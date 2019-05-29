#include <string.h>
#include <errno.h>

#ifdef WIN32
#include <stdio.h>
#include "winsock2.h"
#include <ws2tcpip.h>
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#include <fcntl.h>
#include <arpa/inet.h>
#include <netdb.h>
#endif

#include "lua_amf.h"
#include "buffer.h"
#include "package.h"

#if defined(_MSC_VER)
#include <BaseTsd.h>
typedef SSIZE_T ssize_t;
#endif

struct TCPClient {
    int socket;

#ifdef WIN32
    HANDLE lock; 
    HANDLE thread;
#else
    pthread_mutex_t  lock;
    pthread_t thread;
#endif

    struct buffer * read_buffer;
    struct buffer * write_buffer;

    char host[256];
    int port;

    int lua_ref_id;

    struct TCPClient ** lua_userdata;
};


static void lock_init(struct TCPClient * client)
{
#ifdef WIN32
    client->lock = CreateMutex(
        NULL,              // default security attributes
        FALSE,             // initially not owned
        NULL);             // unnamed mutex

#else
    pthread_mutex_init(&client->lock, 0);
#endif
}

static void lock_lock(struct TCPClient * client)
{
#ifdef WIN32
    WaitForSingleObject(client->lock, INFINITE);
#else
    pthread_mutex_lock(&client->lock);
#endif
}

static void lock_unlock(struct TCPClient * client)
{
#ifdef WIN32
    ReleaseMutex(client->lock);
#else
    pthread_mutex_unlock(&client->lock);
#endif
}

static void lock_free(struct TCPClient * client)
{
#ifdef WIN32
    CloseHandle(client->lock);
    client->lock = INVALID_HANDLE_VALUE;
#else
    pthread_mutex_destroy(&client->lock);
#endif
}



#ifndef WIN32
#define closesocket close
#endif


static FILE * LOG_FILE = 0;
static void OPEN() {
    if (LOG_FILE == 0) LOG_FILE = fopen("c_debug.txt", "a");
}
// #define LOG(...) do { OPEN();  fprintf(LOG_FILE, __VA_ARGS__); fprintf(LOG_FILE, "\n"); fflush(LOG_FILE); } while(0);
#define LOG(...) // printf(__VA_ARGS__); printf("\n");

static void TCPClientClose(struct TCPClient * client) {
    if (client == 0) {
        return;
    }

    lock_lock(client);
    if (client->socket >= 0) {
		LOG("closesocket %d", client->socket);
#ifndef WIN32
		shutdown(client->socket, SHUT_RD);
#endif
        closesocket(client->socket);
        client->socket = -1;
    }

    if (client->read_buffer != 0) {
        _agB_free(client->read_buffer);
        client->read_buffer = 0;
    }

    if (client->write_buffer != 0) {
        _agB_free(client->write_buffer);
        client->write_buffer = 0;
    }

    // free user data
    if (client->lua_userdata != 0) {
		(*client->lua_userdata) = 0;
		client->lua_userdata = 0;
	}

#ifdef WIN32
    if (client->thread != NULL) {
#else
    if (client->thread != 0) {
#endif
        LOG("client thread is running, not free now");
        lock_unlock(client);
        return;
    }

    lock_unlock(client);


    lock_free(client);

    LOG("client thread is done, free %p", client);

    free(client);
}

// struct TCPClient * client = 0;

static void * network_thread(void * p);
static int l_gc(lua_State * L);
static int l_read(lua_State * L);
static int l_write(lua_State * L);
static int l_close(lua_State * L);

static const char * LIB_NAME = "network";

static int l_open(lua_State * L) {
    const char * host = luaL_checkstring(L, 1);
    int port = (int)luaL_checkinteger(L, 2);

    struct TCPClient * client = (struct TCPClient*)malloc(sizeof(struct TCPClient));
	// memset(client, 0, sizeof(struct TCPClient));
	LOG("malloc %p", client);

#ifdef WIN32
    client->thread = NULL;
#endif

    client->socket = -1;
    lock_init(client);
    client->read_buffer = _agB_new(256);
    client->write_buffer = _agB_new(256);
    strcpy(client->host, host);
    client->port = port;
    client->lua_ref_id = LUA_NOREF;

#ifdef WIN32
    DWORD ThreadID;
    client->thread = CreateThread(NULL, 0, (LPTHREAD_START_ROUTINE) network_thread, client, 0, &ThreadID);
#else
	pthread_attr_t tattr;
	pthread_attr_init(&tattr);
	pthread_attr_setdetachstate(&tattr,PTHREAD_CREATE_DETACHED);
    pthread_create(&client->thread, &tattr, network_thread, client);
#endif

    struct TCPClient ** ptr = (struct TCPClient**) lua_newuserdata(L, sizeof(struct TCPClient*));
    *ptr = client;
    client->lua_userdata = ptr;

    if (luaL_newmetatable(L, "__c_network_connection_mt__") == 1) {
        lua_pushcfunction(L, l_gc);
        lua_setfield(L, -2, "__gc");

        lua_getglobal(L, LIB_NAME);
        lua_setfield(L, -2, "__index");
    }
    lua_setmetatable(L, -2);

    return 1;
}


static char *get_ip_str(const struct sockaddr *sa, char *s, size_t maxlen)
{
#ifdef WIN32
    strncpy(s, "unknown host", maxlen);
    return s;
#else

    switch(sa->sa_family) {
        case AF_INET:
            inet_ntop(AF_INET, &(((struct sockaddr_in *)sa)->sin_addr),
                      s, (socklen_t)maxlen);
            break;
            
        case AF_INET6:
            inet_ntop(AF_INET6, &(((struct sockaddr_in6 *)sa)->sin6_addr),
                      s, (socklen_t)maxlen);
            break;
        default:
            strncpy(s, "Unknown AF", maxlen);
            return NULL;
    }
    return s;
#endif
}

static void dispatch_network_status_event(struct TCPClient * client, const char * event)
{
    LOG("dispatch_network_status_event %s", event);
    lock_lock(client);
    struct client_header * header = (struct client_header*)_agB_buffer(client->read_buffer, sizeof(struct client_header));
    header->flag = htonl(0);
    header->cmd = htonl(0);
    header->len = htonl(strlen(event) + sizeof(struct client_header));
    _agB_write(client->read_buffer, event, strlen(event));
    lock_unlock(client);
}

static void * network_thread(void * p)
{
    struct TCPClient * client =  (struct TCPClient*)p;

    dispatch_network_status_event(client, "connecting");

    struct addrinfo *res, *res0;
    
    char portStr[32] = {0};
    sprintf(portStr, "%d", client->port);

    if (getaddrinfo(client->host, portStr, 0, &res0) != 0) {
        goto out;
    }
    

    for (res = res0; res; res = res->ai_next) {
        char _address[128] = {0};
        
        if (res->ai_family == AF_INET6) {
            ((struct sockaddr_in *)res->ai_addr)->sin_port = ntohs(client->port);
        } else {
            ((struct sockaddr_in6 *)res->ai_addr)->sin6_port = ntohs(client->port);
        }
        
        LOG("try connect: %s %d", get_ip_str(res->ai_addr, _address, sizeof(_address)), client->port);

        int fd = socket(res->ai_family, SOCK_STREAM, 0);
        if (fd < 0) {
            LOG("create socket error %s", strerror(errno));
            continue;
        }

#if 0
#ifdef WIN32
        u_long mode = 1;
        int  iRet =  ioctlsocket(client->socket, FIONBIO, &mode);
        if (iRet != NO_ERROR) {
            LOG("ioctlsocket failed with error: %ld\n", iRet);
        }
#else
        int flags = fcntl(client->socket, F_GETFL, 0 );
        fcntl(client->socket, F_SETFL, flags|O_NONBLOCK);
#endif
#endif
        
        int ret = connect(fd, res->ai_addr, res->ai_addrlen);
        if (ret == 0) {
            LOG("connected");
            client->socket = fd;
            break;
        } 

        LOG("connect error %s", strerror(errno));
#if 0
#ifdef WIN32
        int err = WSAGetLastError();
        if (err == WSAEINPROGRESS || err == WSAEWOULDBLOCK) {
            break;
        }
#else
        if (errno == EINPROGRESS || errno == EWOULDBLOCK) {
            break;
        } else {
            CCLOG("connect failed: %s", strerror(errno));
        }
#endif
#endif
        closesocket(fd);
    }

	freeaddrinfo(res0);

    if (client->socket <= 0) {
        goto out;
    }

    dispatch_network_status_event(client, "connected");

    char buff[256];
    while(1) {
		LOG("start read");
        ssize_t len = recv(client->socket, buff, 256, 0);
        if (len <= 0) {
            LOG("recv error %s", strerror(errno));
            break;
        } else {
            LOG("recv bytes %d", (int)len);
        }

        lock_lock(client);
        if (client->read_buffer == 0) {
            lock_unlock(client);
            break;
        }
        _agB_write(client->read_buffer, buff, len);
        lock_unlock(client);
    }
out:
    // TODO: write event
    LOG("connect closed, read thread exit");

    lock_lock(client);
#ifdef WIN32
    CloseHandle(client->thread);
    client->thread = NULL;
#else
    client->thread = 0;
#endif

/*
    if (client->read_buffer == 0) {
        LOG("client is waiting for free, free now");
        lock_unlock(client);

        TCPClientClose(client);
        return 0;
    }
*/
    lock_unlock(client);

    // dispatch_network_status_event(client, "closed");
    TCPClientClose(client);
    return 0;
}


static struct TCPClient * check_client(lua_State * L, int index)
{
    luaL_checktype(L, index, LUA_TUSERDATA);
    struct TCPClient ** ptr = (struct TCPClient**)lua_touserdata(L, index);
	if (ptr == 0) {
        LOG("client is released");
		return 0;
	}

    struct TCPClient * client = *ptr;
    return client;
}

static int l_gc(lua_State * L) {
    struct TCPClient * client = check_client(L, 1);
    LOG("l_gc %p", client);

    if (client == 0) {
        return 0;
    }

#ifndef WIN32
	pthread_t thread = client->thread;
#endif

    TCPClientClose(client);
	
#ifndef WIN32
    if (thread != 0) {
		LOG("waiting thread %p", client);
		// pthread_join(thread, 0);
	}
#endif

    return 0;
}

static int l_write(lua_State * L) {
    struct TCPClient * client = check_client(L, 1);
    if (client == 0) {
        LOG("client is null");
        return 0;
    }

    int cmd = (int)luaL_checkinteger(L, 2);

    const char * mptr = _agB_buffer(client->write_buffer, sizeof(struct client_header));
    size_t offset = mptr - (const char *)_agB_peek(client->write_buffer, 0); // save offset of header

    size_t message_len = lua_encode_amf(L, 3, client->write_buffer); // may change memory address
    size_t package_len = message_len + sizeof(struct client_header);

    const char * buffer_header = (const char *)_agB_peek(client->write_buffer, 0);    
    struct client_header * header = (struct client_header *)(buffer_header + offset); // get header by offset
    header->flag = htonl(1);
    header->cmd = htonl(cmd);

    header->len = htonl(package_len);

    LOG("message len %d/%d", package_len, (int)_agB_size(client->write_buffer));

    if (client->socket < 0) {
        return 0;
    }

    size_t len = _agB_size(client->write_buffer);
    const char * ptr = (const char*)_agB_peek(client->write_buffer, len);

    len = send(client->socket, ptr, len, 0);
    if (len > 0) {
        LOG("send message %d done", (int)len);
        _agB_read(client->write_buffer, len);
    } else {
        LOG("send error %s", strerror(errno));
    }
    
    return 0;
}

static int l_read(lua_State * L) {
    struct TCPClient * client = check_client(L, 1);
    if (client == 0) {
        lua_pushstring(L, "closed");
        return 1;
    }

    lock_lock(client);

    struct client_header * header = (struct client_header*)_agB_peek(client->read_buffer, sizeof(struct client_header));
    if (!header) {
        // LOG("header not enough")
        lock_unlock(client);
        return 0;
    }

    int cmd = ntohl(header->cmd);
    int flag = ntohl(header->flag);
    int len = ntohl(header->len);

    if (_agB_size(client->read_buffer) < (size_t)len) {
        LOG("content not enough [%d,%d] %d/%d", cmd, flag, len, (int)_agB_size(client->read_buffer))
        lock_unlock(client);
        return 0;
    }

    // assert(flag == 1);
     
     // skip header
     _agB_read(client->read_buffer, sizeof(struct client_header));
    len = len - sizeof(struct client_header);

     // read content
     const char * buff = (const char*)_agB_read(client->read_buffer, len);
    if (cmd == 0 && flag == 0) {
        lock_unlock(client);

        // TODO: close socket when error
        if (strcmp(buff, "closed") == 0) {
            LOG("client closed, free");

            // set userdata to null
            struct TCPClient ** ptr = lua_touserdata(L, 1);
            *ptr = 0;

            // close client
            TCPClientClose(client);
        }

        // socket event
        lua_pushlstring(L, buff, len);
        return 1;
    }

     lua_pushinteger(L, cmd);
    if (len == 0) {
        lua_pushnil(L);
    } else {
        lua_decode_amf(L, buff, len);
    }
    lock_unlock(client);

    return 2;
}

static int l_close(lua_State * L) {
    struct TCPClient * client = check_client(L, 1);
    LOG("l_close %p", client);

    if (client == 0) {
        return 0;
    }

    TCPClientClose(client);
	
    return 0;
}

static luaL_Reg reg[] = {
    {"open",  l_open},
    {"write", l_write},
    {"read",  l_read},
    {"close", l_close},
    {0, 0},
};

#ifdef __cplusplus
extern "C" {
#endif

LUALIB_API int luaopen_network(lua_State *L);

LUALIB_API int luaopen_network(lua_State *L)
{

#if LUA_VERSION_NUM == 503
    luaL_newlib(L, reg);
    lua_setglobal(L, LIB_NAME);
#else
    luaL_register(L, LIB_NAME, reg);
    lua_pop(L, 1);
#endif
    return 0;
}

#ifdef __cplusplus
}
#endif
