#ifndef _A_GAME_COMM_PACKAGE_H_
#define _A_GAME_COMM_PACKAGE_H_

#include <stdint.h>

#pragma pack(push, 1)

struct client_header {
	uint32_t len;
	uint32_t flag;
	uint32_t cmd;
};

struct translate_header {
	uint32_t len;
	uint32_t playerid;
	uint32_t flag;
	uint32_t cmd;
};

#define LOGOUT_NORMAL		0
#define LOGOUT_ANOTHER_LOGIN	1
#define LOGOUT_ADDICTED    	2
#define LOGOUT_ADMIN_KICK	3
#define LOGOUT_CONNECT		4
#define LOGOUT_ADMIN_BAN	5

#define RET_SUCCESS			0
#define RET_ERROR			1
#define RET_EXIST			2
#define RET_NOT_EXIST			3
#define RET_PARAM_ERROR			4
#define RET_INPROGRESS			5
#define RET_MAX_LEVEL			6
#define RET_DEPEND			7
#define RET_RESOURCES			8
#define RET_FULL			9
#define RET_NOT_ENOUGH			10
#define RET_PREMISSIONS			11
#define RET_COOLDOWN			12
#define RET_ALREADYAT			13
#define RET_SERVICE_STATUS_ERROR	14

#define RET_CHARACTER_NOT_EXIST		RET_NOT_EXIST

#define RET_CHARACTER_STATUS_BAN	20
#define RET_CHARACTER_STATUS_MUTE	21
#define RET_CHARACTER_STATUS_ADDICTED	22

#define RET_VIP_PREMISSIONS			30

#define RET_TARGET_NOT_EXIST		50
#define RET_CHARACTER_EXIST		51
#define RET_CHARACTER_NAME_EXIST	52
#define RET_FIGHT_FAILED		53
#define RET_REWARD_NOT_EXIST		54

#define RET_KING_COUNTRY		100
#define RET_KING_LEVEL			101
#define RET_KING_PRESTIGE		102
#define RET_KING_TITLE			103
#define RET_KING_TITLE_INVALID		104
#define RET_COMPOSE			105

#define RET_SALARY_NOT_EXIST		106
#define RET_TAX_LIMIT			107

#define RET_BUILDING_INVALID		201
#define RET_BUILDING_LEVEL_SCHOOL	202
#define RET_BUILDING_MAX_LEVEL		203

#define RET_TECHNOLOGY_INVALID		211
#define RET_TECHNOLOGY_MAX_LEVEL	212

#define RET_HERO_BUSY			221
#define RET_HERO_EXIST			222
#define RET_HERO_GROW_LIMIT		223
#define RET_HERO_INUSE			224
#define RET_HERO_INVALID		225
#define RET_HERO_LEVEL			226
#define RET_HERO_NOT_EXIST		227
#define RET_HERO_NOT_INUSE		228
#define RET_HERO_NOT_TRANING		229
#define RET_HERO_NOT_VISIT		230
#define RET_HERO_RELATIONSHIP		231
#define RET_HERO_RELATIONSHIP_FULL	232
#define RET_HERO_TITLE_INVALID		233
#define RET_HERO_TRANING		234
#define RET_HERO_VISIT			235
#define RET_HERO_INUSE_FULL		236

#define RET_RESOURCE_NOT_ENOUGH		250
#define RET_RESOURCE_COIN_NOT_ENOUGH	251
#define RET_RESOURCE_MDEAL_NOT_ENOUGH	252
#define RET_RESOURCE_MONEY_NOT_ENOUGH	252
#define RET_RESOURCE_ORDER_NOT_ENOUGH	253
#define RET_RESOURCE_WOOD_NOT_ENOUGH	254
#define RET_MERCHANDISE_INVALID		255
#define RET_RESOURCE_MONEY_NOT_ENOUGH_2	256

#define RET_EQUIP_GEM_REPEAT		260
#define RET_EQUIP_INUSE			261
#define RET_EQUIP_INVALID		262
#define RET_EQUIP_LEVEL			263
#define RET_EQUIP_MAX_LEVEL		264
#define RET_EQUIP_MIN_LEVEL		265
#define RET_EQUIP_NOT_EXIST		267
#define RET_EQUIP_POS			268
#define RET_EQUIP_TYPE			269

#define RET_ITEM_NOT_ENOUGH		280
#define RET_GEM_INVALID			281
#define RET_GEM_MAX_LEVEL		282
#define RET_GEM_NOT_ENOUGH		283
#define RET_GEM_NOT_EXIST		284
#define RET_BAG_FULL			285

#define RET_QUEST_DOING			290
#define RET_QUEST_DONE			291
#define RET_QUEST_INVALID		292

#define RET_COOLDOWN_HERO_EXCHANGE	301
#define RET_COOLDOWN_HERO_VISIT		302

#define RET_DAILY_LIMIT_FIRE		310
#define RET_DAILY_LIMIT_MERCHANDISE	311
#define RET_DAILY_LIMIT_SALARY		312
#define RET_DAILY_LIMIT_STORY		313
#define RET_DAILY_LIMIT_TAX		    314
#define RET_DAILY_LIMIT_HORSE		315
#define RET_DAILY_LIMIT_DONATE		316

#define RET_STORY_INVALID		320
#define RET_STORY_NOT_OPEN		321
#define RET_FIRE_LAYER_ERROR		322
#define RET_STORY_COOLDOWN		323

#define RET_TACTIC_BAG_FULL		330
#define RET_TACTIC_EXP_NOT_ENOUGH	331
#define RET_TACTIC_INVALID		332
#define RET_TACTIC_MAX_LEVEL		333
#define RET_TACTIC_NOT_EXIST		334
#define RET_TACTIC_TEACHER_INVALID	335
#define RET_TACTIC_TEACHER_NOT_EXIST	336

#define RET_REWARD_INVALID		400	// 无效奖励
#define RET_REWARD_DONE			401	// 奖励已领取
#define RET_REWARD_EXPIRED		402	// 奖励已过期
#define RET_SIGN_FULL			403	// 签到已满
#define RET_SIGN_ALREADY_SIGNED		404	// 当天已签到

#define RET_ARENA_COOLDOWN		500
#define RET_ARENA_LIMIT			501
#define RET_ARENA_POSITION_INVALID	502

#define RET_BATTLE_EXIST		601
#define RET_BATTLE_INVALID		602
#define RET_BATTLE_NOT_EXIST		603

#define RET_COUNTRY_BATTLE		630
#define RET_COUNTRY_FRIEND		631
#define RET_COUNTRY_LINK		632
#define RET_COUNTRY_MATCH		633
#define RET_COUNTRY_PROTECTED		634

#define RET_CHANNEL_INVALID		701
#define RET_CONTACT_SELF		702

#define RET_GUILD_EXIST			801
#define RET_GUILD_LEADER		802
#define RET_GUILD_MEMBER		803
#define RET_GUILD_NAME_EXIST		804
#define RET_GUILD_NOT_EXIST		805
#define RET_GUILD_PREMISSION		806
#define RET_GUILD_PREMISSIONS		807
#define RET_GUILD_REQUEST_INPROGRESS	808
#define RET_GUILD_REQUEST_NOT_EXIST	809


#define NOTIFY_PROPERTY			1	// 属性
#define NOTIFY_RESOURCE			2	// 资源
#define NOTIFY_BUILDING			3	// 建筑状态 key = building.id
#define NOTIFY_TECHNOLOGY		4	// 科技状态 key = technology.id
#define NOTIFY_CITY			5	// 城池属性
#define NOTIFY_HERO_LIST		6	// 武将列表
#define NOTIFY_HERO			7	// 武将属性 key = hero.id
#define NOTIFY_GEM_COUNT		8	// 宝石数量 key = item.id
#define NOTIFY_COOLDOWN			9	// CD	
#define NOTIFY_EQUIP_LIST		10	// 装备列表
#define NOTIFY_EQUIP			11	// 装备属性 key = equip.uuid
#define NOTIFY_FARM			12	// 农场状态
#define NOTIFY_STRATEGY			13	// 策略值
#define NOTIFY_STORY			14	// 推图状态 key = story.id
#define NOTIFY_COMPOSE			15	// 布阵
#define NOTIFY_DAILY			16
#define NOTIFY_QUEST			17	// 任务 key = quest.id

#define NOTIFY_ARENA_ATTACK		18	// 竞技场攻击通知

#define NOTIFY_GUILD_REQUEST 		19	// 请求加入军团 [gid, [pid, name]]
#define NOTIFY_GUILD_JOIN 	 	20	// 加入军团     [gid, [pid, pname]]
#define NOTIFY_GUILD_LEAVE 	 	21	// 离开军团     [gid, [pid, pname], [oid, oname]]
#define NOTIFY_GUILD_NOTIFY 	 	22	// 军团公告     [gid, notify]
#define NOTIFY_GUILD_LEADER 	 	23	// 团长变更     [gid, [leaderid, leadername], [oid, oname]]
#define NOTIFY_GUILD_TITLE 	 	24	// 职位变更 	[gid, [pid, pname], [oid, oname], changetype, title]
#define NOTIFY_GUILD_AUDIT 	 	25	// 同意加入变更 [[gid, gname], [oid, oname], type];

#define NOTIFY_MAIL_NEW 	 	26	// 新邮件通知   [id, type, title, status, [fromid, fromname]]

#define NOTIFY_FIRE 	 		27

#define NOTIFY_TACTIC 	 	28
#define NOTIFY_TACTIC_STATUS 	29

#define NOTIFY_BATTLEFIELD_JOIN  	31 // [bid, id, name, country]
#define NOTIFY_BATTLEFIELD_LEAVE 	32 // [bid, id]
#define NOTIFY_BATTLEFIELD_LINE_CHANGE 	33 // [bid, id, line, pos, speed, hp]
#define NOTIFY_BATTLEFIELD_ATTACK 	34 // [bid, id1, id2, fightid, winner]
#define NOTIFY_BATTLEFIELD_ATTACK_WALL 	35 // [bid, id, left]
#define NOTIFY_BATTLEFIELD_FINISHED 	36 // [bid]
#define NOTIFY_BATTLEFIELD_LINE_GETOUT 	37 // [bid, id]

#define NOTIFY_KING_AVATAR_CHANGE       38	// 君主形象改变

#define NOTIFY_ITEM_COUNT		39	// 道具数据改变
// [id, count]
#define NOTIFY_DISPLAY_MESSAGE		40	// 显示消息 [type, message]


#define NOTIFY_BATTLEFIELD_CREATE 	41 	// 国战开始 [bid, [country, city], [country, city]]
#define NOTIFY_BATTLEFIELD_CITY_CHANGE  42	// 城市变更 [city, country, [guildid, guildname]]
#define NOTIFY_BATTLEFIELD_COUNTRY_CHANGE  43   // 国家变更 [country, score]
#define NOTIFY_BATTLEFIELD_PLAYER_PRIVATE_INFO_CHANGE  44  // 玩家个人信息变更 [cd]

#define NOTIFY_MERCHANDISE_CHANGE	45	// 资源可交易次数 [id, left, [id, count], [id, count]]

#define NOTIFY_BATTLEFIELD_PLAYER_PUBLIC_INFO_CHANGE 46  // 玩家公开信息变更 [战功, 威望]

#define NOTIFY_RESOURCE_AUTO_INCREASE 	47 	// 资源

#define NOTIFY_GUILD_BOSS_SETTING 	48	// boss时间改变

#define NOTIFY_REWARD_CHANGE		49	// [from, ....]
#define NOTIFY_BATTLEFIELD_ACTIVITY_STATUS 50 	// [btype,start,duration,status,[battleID,[countryA,cityA],[countryB,cityB]]]
#define NOTIFY_ADDICTED_CHANGE	51	// [type, hour]  type:0 登录通知   1 每小时弹框 2 踢出弹框

#define NOTIFY_CONTACT_ADD  52	// [[id, name], type]  被加好友通知

#define NOTIFY_GUILD_5XING_CHANGE 53   // [[id,name,head,times], ...];
#define NOTIFY_GUILD_5XING_REWARD 54   // [[id,name, [[type,id,value],...]], ...]
#define NOTIFY_GUILD_5XING_PLAYER_TIMES_CHANGE 55  // [times]

#define NOTIFY_SIGN_REWARD_CHANGE 56  // [[time, sign, xsign], resign_cost, reward_flag]
#define NOTIFY_ACTIVITY_INFO_CHANGE 57  // [id, value, max]
#define NOTIFY_ACTIVITY_REWARD_CHANGE 58  // [flag]

#define NOTIFY_BUFFER				59
#define NOTIFY_VIP_CHANGE	60

#define NOTIFY_HORSE 61
#define NOTIFY_CARD	62

#define SEX_MALE		1	
#define SEX_FEMALE		2

#define C_ECHO 		 0 		//登入请求

#define C_LOGIN_REQUEST  1 		//登入请求
// [sn, "account", "playerid"]
#define C_LOGIN_RESPOND  2 		//登入返回
// [sn, result, playerid]

#define C_LOGOUT_REQUEST  3 		//登出请求
#define C_LOGOUT_RESPOND  4 		//登出返回

#define C_QUERY_PLAYER_REQUEST 5 	//查询玩家信息请求
// [sn, playerid]
#define C_QUERY_PLAYER_RESPOND 6 	//查询玩家信息返回
// [sn, result, playerid, "name",  exp, country,
//	force, power, freepoint, "bio", prestige, strategy,
//	level, title, tax, salary, head, sex]

#define C_CREATE_PLAYER_REQUEST 7	//创建角色请求
// [sn, "name", country, "BIO", head, sex]

#define C_CREATE_PLAYER_RESPOND 8	//创建角色返回
// [sn, result, "info"]

#define C_UPGRADE_BUILDING_REQUEST 	9	//升级请求
// [sn, type]

#define C_UPGRADE_BUILDING_RESPOND	10	//升级返回
// [sn, result, "info"]

#define C_QUERY_BUILDING_REQUEST	11	//查询建筑请求
// [sn]

#define C_QUERY_BUILDING_RESPOND	12	//查询建筑返回
// [sn, result, [type, level, delay], ...]


#define C_CANCEL_BUILDING_REQUEST 	13	//取消建筑请求
// [sn, type]

#define C_CANCEL_BUILDING_RESPOND	14	//取消建筑返回
// [sn, result, "info"]

#define C_QUERY_RESOURCES_REQUEST	15	//查询资源请求
// [sn]

#define C_QUERY_RESOURCES_RESPOND	16	//查询资源返回
// [
//       sn, result,
//       [id, count]

//       [wood, count, speed],
//       [stone, count, speed],
//       [bronze, count, speed],
//       [food, count, speed], 
//       [coin, count, speed],
//       [work_people, total_people],
//       [pre_soldier,  count, speed],
//       [soldier_count]]
// ]

#define C_QUERY_TECHNOLOGY_REQUEST	17	//查询科技请求
// [sn]

#define C_QUERY_TECHNOLOGY_RESPOND	18	//查询科技返回
// [sn, result, [type, level, delay], ...]

#define C_UPGRADE_TECHNOLOGY_REQUEST	19	//升级科技请求
// [sn, type]

#define C_UPGRADE_TECHNOLOGY_RESPOND	20	//升级科技返回
// [sn, result, "info"]

#define C_CANCEL_TECHNOLOGY_REQUEST	21	//取消升级科技请求
// [sn, type]

#define C_CANCEL_TECHNOLOGY_RESPOND	22	//取消升级科技返回
// [sn, result, "info"]

#define C_RECRUIT_SOLDIER_REQUEST	23	//征兵请求
// [sn, count]

#define C_RECRUIT_SOLDIER_RESPOND	24	//征兵返回
// 返回资源
// [sn, result, "info"]

#define C_QUERY_HERO_REQUEST		25	//查询武将请求
// [ sn, type]   1 当前武将 2 可招募  3 待招募 4 声望武将

#define C_QUERY_HERO_RESPOND		26	//查询武将返回
// [sn, result, 1, 
//     [ 1  id,  2  exp, 3 level,  4 grow,  5 stat,
//          6 soldier_type,  7 soldier_count,
//          8 train_type, 9 train_start_time,  10  train_delay
//          11 title  12 employ_time   13 t  14 relationship  15 combat_effective ], ...]
// [sn, result, 2, [type, exp, level, grow], ...]
// [sn, result, 3, type, ...]
// [sn, result, 4, [type, time, r], ...]


#define C_EMPLOY_HERO_REQUEST		27	//招募武将请求
// [ sn, type]

#define C_EMPLOY_HERO_RESPOND		28	//招募武将返回
// [sn, result, "info"]

#define C_FIRE_HERO_REQUEST		29	//解散武将请求
// [ sn, type]

#define C_FIRE_HERO_RESPOND		30	//解散武将返回
// [sn, result, "info"]

#define C_ASSIGN_SOLDIER_REQUEST	31	//配兵请求
// [ sn, [hero_type, soldier_type, soldier_count], ...]

#define C_ASSIGN_SOLDIER_RESPOND	32	//配兵返回
// [sn, result, heroid, soldier_type, soldier_count]

#define C_QUERY_BATTLE_REQUEST		33	//查询军情请求
// [ sn ]

#define C_QUERY_BATTLE_RESPOND		34	//查询军情返回
// [sn, result, [id,type,x,y,target,stat,left,fightid], ...]

#define C_START_BATTLE_REQUEST		35	//出征请求
// [ sn, x,y,[hero,...]]

#define C_START_BATTLE_RESPOND		36	//出征返回
// [sn, result, "info"]

#define C_CANCEL_BATTLE_REQUEST		37	//取消出征请求
// [ sn, id];

#define C_CANCEL_BATTLE_RESPOND		38	//取消出征返回
// [sn, result, "info"]

#define C_TICK_REQUEST			39	//心跳
// [sn];

#define C_TICK_RESPOND			40	//心跳
// [sn, result, now]

#define C_QUERY_FIGHT_REQUEST		41	//查询战斗请求
// [sn, fightid]

#define C_QUERY_FIGHT_RESPOND		42	//查询战斗返回
// [sn, result, 
//      [[pos,playerid,hero,hero_level,soldier_type, soldier_level, soldier_count, soldier_dead, soldier_relive], ...],
//      [[pos,playerid,hero,hero_level,soldier_type, soldier_level, soldier_count, soldier_dead, soldier_relive], ...],
//      [[type,count,used],...]]

#define C_QUERY_MAP_REQUEST		43	//查询战斗请求
// [sn, x, y]

#define C_QUERY_MAP_RESPOND		44	//查询战斗返回
// [sn, result, [x, y, playerid], ...]

#define C_QUERY_COOLDOWN_REQUEST	45	//查询cd状态请求
// [sn]

#define C_QUERY_COOLDOWN_RESPOND	46	//查询cd状态返回
// [sn, result, [type, limit, value], ...]

#define C_QUERY_CITY_REQUEST		47	//查询城市请求
// [sn]

#define C_QUERY_CITY_RESPOND		48	//查询城市返回
// [sn, result, exp, level, x, y, guard ...]

#define C_SET_CITY_GUARD_REQUEST	49	//设置守卫请求
// [sn, g1, g2, g3, g4, g5]

#define C_SET_CITY_GUARD_RESPOND	50	//设置守卫返回
// [sn, result, info]

#define C_VISIT_HERO_REQUEST		51	//拜访武将请求
// [sn, heroid, type]

#define C_VISIT_HERO_RESPOND		52	//拜访武将返回
// [sn, result, heroid, get?, old, new]

#define C_EXCHANGE_HERO_REQUEST		53	//武将传授请求
// [sn, h1, h2]

#define C_EXCHANGE_HERO_RESPOND		54	//武将传授返回
// [sn, result, h1, h2]

#define C_GROW_HERO_REQUEST		55	//武将成长请求
// [sn, heroid, type]

#define C_GROW_HERO_RESPOND		56	//武将成长返回
// [sn, result, id, value]

#define C_QUERY_EQUIP_REQUEST		57	//查询装备列表请求
// [sn]
#define C_QUERY_EQUIP_RESPOND		58	//查询装备列表返回
// [sn result, [uuid, id, limit, level, gem, ...], ... ]

#define C_USE_EQUIP_REQUEST		59	//使用装备请求
// [sn, hero, uuid, uuid, uuid, uuid, uuid]

#define C_USE_EQUIP_RESPOND		60	//使用装备返回
// [sn, result, info]

#define C_UPGRADE_EQUIP_REQUEST		61	//升级装备请求
// [sn, uuid, type]

#define C_UPGRADE_EQUIP_RESPOND		62	//升级装备返回
// [sn, result, uuid, level]

#define C_EQUIP_SET_GEM_RQUEST		63	//镶嵌请求
// [sn, uuid, gem1, gem2, gem3]

#define C_EQUIP_SET_GEM_RESPOND		64	//向前返回
// [sn, result, uuid];

#define C_BUY_EQUIP_REQUEST		65	//购买装备请求
// [sn, type]
#define C_BUY_EQUIP_RESPOND		66	//购买装备返回
// [sn result, uuid, id, limit, level, gem, ...]

#define C_SELL_EQUIP_REQUEST		67	//出售装备请求
// [sn, uuid]
#define C_SELL_EQUIP_RESPOND		68	//出售装备返回
// [sn result, uuid]

#define C_QUERY_GEM_REQUEST		69	//查询宝石请求
// [sn]
#define C_QUERY_GEM_RESPOND		70	//查询宝石返回
// [sn, result, [id, count], ...]

#define C_BUY_GEM_REQUEST		71	//购买宝石请求
// [sn, id, count]

#define C_BUY_GEM_RESPOND		72	//购买宝石返回
// [sn, result, id, count]

#define C_SELL_GEM_REQUEST		73	//出售宝石请求
// [sn, id, count]
#define C_SELL_GEM_RESPOND		74	//出售宝石返回
// [sn, result, id, count]

#define C_USE_ITEM_REQUEST		75	//使用道具请求
// [sn, id, count]

#define C_USE_ITEM_RESPOND		76	//使用道具返回
// [sn, result id, count]

#define C_TRAIN_HERO_REQUEST		77	//开始训练武将请求
// [sn, hero, type, dely]

#define C_TRAIN_HERO_RESPOND		78	//开始训练武将返回
// [sn, result, heroid]

#define C_FINISH_TRAIN_HERO_REQUEST	79	//结束训练请求
// [sn, hero]

#define C_FINISH_TRAIN_HERO_RESPOND	80	//结束训练返回
// [sn, result, hero]
//

#define C_GEMSTONE_COMPOSE_REQUEST	81	//宝石合成请求
// [sn, id, bag]

#define C_GEMSTONE_COMPOSE_RESPOND	82	//宝石合成返回
// [sn, result, info}]

#define C_QUERY_FARM_REQUEST		83	//查询农场
// [sn]
#define C_QUERY_FARM_RESPOND		84	//查询农场
// [sn, result, [id, type, plant_time], ...]

#define C_FARM_PLANT_REQUEST		85	//农场种植
// [sn, id, type]

#define C_FARM_PLANT_RESPOND		86	//农场种植
// [sn, result, info]

#define C_FARM_GAIN_REQUEST		87	//农场收获
// [sn, type, id]

#define C_FARM_GAIN_RESPOND		88	//农行收获
// [sn, result, type, [id, [rtype, rvalue], ...]

#define C_QUERY_STRATEGY_REQUEST	89	//查询策略请求
// [sn]

#define C_QUERY_STRATEGY_RESPOND	90	//查询策略返回
// [sn, result, [id, exp, level, cd], ...]

#define C_USE_STRATEGY_REQUEST		91	//使用策略请求
// [sn, id]

#define C_USE_STRATEGY_RESPOND		92	//使用策略返回
// [sn, result, id]

#define C_SET_KING_TITLE_REQUEST	93	//设置君主官职请求
// [sn, titleid]

#define C_SET_KING_TITLE_RESPOND	94	//设置君主官职返回
// [sn, result, titleid]

#define C_SET_HERO_TITLE_REQUEST	95	//设置武将官职请求
// [sn, heroid, titleid]

#define C_SET_HERO_TITLE_RESPOND	96	//设置武将官职返回
// [sn, result, heroid, titleid]

#define C_SET_PLAYER_POINT_REQUEST	97	//加点请求
// [sn, force, power]

#define C_SET_PLAYER_POINT_RESPOND	98	//加点返回
// [sn, result, force, power, freepoing]

#define C_SET_HERO_COMPOSE_REQUEST	99	//设置阵形
// [sn, id, [h1, t1], ...]

#define C_SET_HERO_COMPOSE_RESPOND	100	//设置阵形
// [sn, result, id, [h1, t1], ...]

#define C_QUERY_HERO_COMPOSE_REQUEST	101	//查询阵形
// [sn]

#define C_QUERY_HERO_COMPOSE_RESPOND	102	//查询阵形
// [sn, [id, [h1, t1], ...], ...]

#define C_DATA_CHANGE_REQUEST		103	//状态更新 (unused)

#define C_PLAYER_DATA_CHANGE 		104	//状态更新
// [sn, result, [type, ...], ...]

#define C_QUERY_STORY_REQUEST		105	//查询剧情请求
// [sn]
#define C_QUERY_STORY_RESPOND		106	//查询剧情返回
// [sn, result, [id,flag], ...]


#define C_DO_STORY_REQUEST		107	//剧情战斗请求
// [sn, id]
#define C_DO_STORY_RESPOND		108	//剧情战斗返回
// [sn, result, fightid, winner, fightid, [[type,id,count],...]]

#define C_BUILD_CITY_DEFENSE_REQUEST	109	//建造城防请求
// [sn, id(1-5), count]

#define C_BUILD_CITY_DEFENSE_RESPOND	110	//建造城防返回
// [sn, result, id, count]

#define C_LEVY_TAX_REQUEST		111	//征收请求
// [sn, force]

#define C_LEVY_TAX_RESPOND		112	//征收返回
// [sn, result, value]

#define C_GET_SALARY_REQUEST		113	//领取俸禄请求
// [sn]

#define C_GET_SALARY_RESPOND		114	//领取俸禄返回
// [sn, result, count]

#define C_EXCHANGE_EQUIP_REQUEST	115     // 交换装备请求
// [sn, hero1, hero2, position, ...]

#define C_EXCHANGE_EQUIP_RESPOND	116 	// 交换装备返回
// [sn, result, hero1, hero2]

#define C_QUERY_QUEST_REQUEST		117     // 查询任务请求
// [sn, type] 

#define C_QUERY_QUEST_RESPOND		118	// 查询任务返回
// [sn, result, [id, status, count], ...]

#define C_ACCEPT_QUEST_REQUEST		119	// 接受任务请求
// [sn, id]

#define C_ACCEPT_QUEST_RESPOND		120	// 接受任务返回
// [sn, result]

#define C_FINISH_QUEST_REQUEST		121	// 完成任务请求
// [sn, id]

#define C_FINISH_QUEST_RESPOND		122	// 完成任务返回
// [sn, result]

#define C_SUBMIT_QUEST_REQUEST		123	// 提交任务请求 
// [sn, id]

#define C_SUBMIT_QUEST_RESPOND		124	// 提交任务返回
// [sn, result]

#define C_CANCEL_QUEST_REQUEST		125	// 取消任务请求 
// [sn, id]

#define C_CANCEL_QUEST_RESPOND		126	// 取消任务返回
// [sn, result]

#define C_CHANGE_BIO_REQUEST		127	// 修改bio请求
// [sn, BIO];
#define C_CHANGE_BIO_RESPOND		128	// 修改bio返回
// [sn, result, info]

#define C_CHANGE_HEAD_REQUEST		129	// 修改头像请求
// [sn, head]
#define C_CHANGE_HEAD_RESPOND		130	// 修改头像返回
// [sn, result, info]

#define C_FINISH_TAX_EVENT_REQUEST	131	// 征收事件请求
// [sn, select]

#define C_FINISH_TAX_EVENT_RESPOND	132	// 征收事件返回
// [sn, result, info]

#define C_QUERY_FLAG_REQUEST		133	// 查询标志位请求
// [sn]
#define C_QUERY_FLAG_RESPOND		134	// 查询标志位返回
// [sn, result, flags, ...]

#define C_SET_FLAG_REQUEST		135	// 设置标志位请求
// [sn, flag, ...]
#define C_SET_FLAG_RESPOND		136	// 设置标志位返回
// [sn, result ]

#define C_FARM_GAIN_ALL_REQUEST		137	//农场全部收获
// [sn, type]
#define C_FARM_GAIN_ALL_RESPOND		138	//农场全部收获
// [sn, result, type, [id, [rtype, rvalue], ...], ...]

#define C_SET_COUNTRY_REQUEST		139	// 设置国家
// [sn, country]
#define C_SET_COUNTRY_RESPOND		140	// 设置国家
// [sn, result, country]

#define C_CLEAN_COOLDOWN_REQEUST	141	// 清除建筑cd请求
// [sn, id, ...]

#define C_CLEAN_COOLDOWN_RESPOND	142	// 清除建筑cd返回
// [sn, result, id, ...]


#define C_FIRE_QUERY_REQUEST		143	// 火烧联营进度查询请求
// [sn]

#define C_FIRE_QUERY_RESPOND		144	// 火烧联营进度查询返回
// [sn, result, max, cur]

#define C_FIRE_RESET_REQUEST		145	// 火烧联营进度重置请求
// [sn]

#define C_FIRE_RESET_RESPOND		146	// 火烧联营进度重置返回
// [sn, result]

#define C_FIRE_ATTACK_REQUEST		147	// 火烧联营战斗请求
// [sn, id]

#define C_FIRE_ATTACK_RESPOND		148	// 火烧联营战斗返回
// [sn, result, id, winner, fightID, [[type, id, value], ...]]	

#define C_FIRE_AUTO_REQUEST		149	// 火烧联营自动战斗请求
// [sn]

#define C_FIRE_AUTO_RESPOND		150	// 火烧联营自动战斗返回
// [sn, result, [id, [[type, id, value], ...]...]


#define C_TACTIC_QUERY_REQUEST	151	// 查询
// [sn]

#define C_TACTIC_QUERY_RESPOND	152
// [sn, result, exp, teachers, [uuid, id, level, hero, pos], ...]

#define C_TACTIC_VISIT_REQUEST	153	// 拜访
// [sn, teacher]

#define C_TACTIC_VISIT_RESPOND	154
// [sn, result, treacher, uuid, id, teachers]

#define C_TACTIC_MOVE_REQUEST	155	// 使用
// [sn, uuid, heroid, pos]

#define C_TACTIC_MOVE_RESPOND	156
// [sn, result, uuid, heroid, pos]

#define C_TACTIC_LEARN_REQUEST	157	// 学习
// [sn, uuid]

#define C_TACTIC_LEARN_RESPOND	158	 
// [sn, result, uuid, exp]

#define C_TACTIC_LEVELUP_REQUEST	159	// 升级
// [sn, uuid]

#define C_TACTIC_LEVELUP_RESPOND	160	
// [sn, result, uuid, level]

#define C_KING_AVATAR_CHANGE_REQUEST	161	// 改变君主形象请求
// [sn, body, head, weapon]

#define C_KING_AVATAR_CHANGE_RESPOND	162	// 改变君主形象返回
// [sn, body, head, weapon]
//
#define C_INVITE_HERO_REQUEST           163 // 邀请武将
// [sn, hid]

#define C_INVITE_HERO_RESPOND           164 // 邀请武将
// [sn, result, hid]

#define C_QUERY_ITEM_REQUEST		165	//查询道具请求
// [sn]

#define C_QUERY_ITEM_RESPOND		166	//查询道具返回
// [sn, result, [id, count], ...]

#define C_BUY_ITEM_REQUEST		167	//购买道具请求
// [sn, id, count]

#define C_BUY_ITEM_RESPOND		168	//购买道具返回
// [sn, result, id, count]

#define C_SELL_ITEM_REQUEST		169	//出售道具请求
// [sn, id, count]

#define C_SELL_ITEM_RESPOND		170	//出售道具返回
// [sn, result, id, count]

#define C_BAG_MOVE_REQUEST		171	//移动装备/宝石/道具请求
// [sn, from, to]

#define C_BAG_MOVE_RESPOND		172	//移动装备/宝石/道具返回
// [sn, result]

#define C_RESET_FIGHT_COUNT_REQUEST	173	// 重置战役战斗次数请求
// [sn, battleid]

#define C_RESET_FIGHT_COUNT_RESPOND	174	// 重置战役战斗次数返回
// [sn, result]

#define C_SET_KING_FLAG_REQUEST		175	// 设置君主旗帜请求
// [sn, flag]

#define C_SET_KING_FLAG_RESPOND		176	// 设置君主旗帜返回
// [sn, result, flag]

#define C_DO_STORY_AUTO_REQUEST		177	// 扫荡请求
// [sn, fightid]

#define C_DO_STORY_AUTO_RESPOND		178	// 扫荡返回
// [sn, result, fightid, winner, fightid, [[type,id,count],...]]

#define C_UPGRADE_EQUIP_RANK_REQUEST	179	// 升阶装备请求
// [sn, uuid]

#define C_UPGRADE_EQUIP_RANK_RESPOND	180	// 升阶装备返回
// [sn, result, uuid, id]

#define C_BAG_MOVE_ADVANCE_REQUEST	181	// 挪背包，武将返回
// [sn, [frombag, frompos], [tobag, topos]]

#define C_BAG_MOVE_ADVANCE_RESPOND	182	// 挪背包，武将返回
// [sn, result, [frombag,  frompos], [tobag, topos]]

#define C_EXCHANGE_REQUEST		183	// 兑换请求
// [sn, id, count]

#define C_EXCHANGE_RESPOND		184	// 兑换返回
// [sn, result, id, count]

#define C_QUERY_MERCHANDISE_REQUEST	185	// 资源交易查询请求
// [sn]

#define C_QUERY_MERCHANDISE_RESPOND	186	// 资源交易查询返回
// [sn, result, [id, left, get[id, count], cost[id, count]], ...]

#define C_MERCHANDISE_REQUEST		187	// 资源交易请求
// [sn, id]

#define C_MERCHANDISE_RESPOND		188	// 资源交易返回
// [sn, result, [id, left, get[id, count], cost[id, count]]]

#define C_QUERY_OTHER_HERO_REQUEST	189	// 查询别人武将信息
// [sn, id]

#define C_QUERY_OTHER_HERO_RESPOND      190     // 查询别人武将信息
// [sn, result, pid, [id, level, grow, soldier_count, title, equips[[id, level, gem1, gem2, gem3, pos],...]], ...]

#define C_QUERY_FIGHT_DATA_REQUEST	191	// 查询战报请求
// [sn, id, type]

#define C_QUERY_FIGHT_DATA_RESPOND	192	// 查询战报返回
// [sn, result, id, type, data]

#define C_QUERY_REWARD_REQUEST		193	// 查询可领取奖励请求
// [sn]

#define C_QUERY_REWARD_RESPOND		194	// 查询可领取奖励返回
// [sn, result, [from, ...]]

#define C_RECEIVE_REWARD_REQUEST	195	// 领取奖励请求
// [sn, from]

#define C_RECEIVE_REWARD_RESPOND	196	// 领取奖励返回
// [sn, result, from, [[type, key, value], ...]]


#define C_SET_HERO_COMBAT_EFFECTIVE_REQUEST 197	// 设置武将战力
// [sn, [id, value], ...]

#define C_SET_HERO_COMBAT_EFFECTIVE_RESPOND 198	// 设置武将战力
// [sn, result]

#define C_CHANGE_VISIT_HERO_REQUEST	 199    // 刷新拜访武将列表
// [sn]

#define C_CHANGE_VISIT_HERO_RESPOND	 200	
// [sn, result]

#define C_SIGN_QUERY_REQUEST  201	// 查询签到记录
// [sn, time]   time 所查询的月份中的任一时间

#define C_SIGN_QUERY_RESPOND  202
// [sn, result, [time, sign, xsign], resign_cost, reward_flag]
// sign  签到记录  整数，按位
// xsign 补签记录  整数，按位
// reward_flag 奖励标识 从低位开始，2位表示一个奖励
//      id 从1开始，最低两位标识id = 1 的奖励状态
// status
//      状态 00 不可领取 01 可领取  10 已领取 11 备用

#define C_SIGN_SIGN_REQUEST	203
// [sn, day]  day 日期, 0表示当天, 1 表示补签

#define C_SIGN_SIGN_RESPOND	204
// [sn, resut, sign, xsign]

#define C_SIGN_REWARD_REQUEST	205
// [sn, id]

#define C_SIGN_REWARD_RESPOND	206
// [sn, result, id]

#define C_ACTIVITY_INFO_QUERY_REQUEST 	207
// [sn]
#define C_ACTIVITY_INFO_QUERY_RESPOND 	208
// [sn, result, haveReward, [id, value, max], ...]

#define C_ACTIVITY_REWARD_REQUEST 	209
// [sn]
#define C_ACTIVITY_REWARD_RESPOND 	210
// [sn, result, haveReward, [[type, id, value], ...]]

#define C_QUERY_RANK_REQUEST		211
// [sn]
#define C_QUERY_RANK_RESPOND		212
// [sn, result, [[pid, exp], ...], [[pid,prestige]...]]

#define C_DO_STORY_QUERY_LOG_REQUEST 213 // 查询试炼塔log
// [sn. id]
#define C_DO_STORY_QUERY_LOG_RESPOND 214
// [sn. result, [time, pid, name, fid], ...]

#define C_QUERY_HORSE_REQUEST 215
#define C_QUERY_HORSE_RESPOND 216

#define C_TRAIN_HORSE_REQUEST 217
#define C_TRAIN_HORSE_RESPOND 218

#define C_DONATE_REQUEST 219
#define C_DONATE_RESPOND 220

#define C_USE_CARD_REQUEST 221
#define C_USE_CARD_RESPOND 222

////////////////////////////////////////////////////////////////////////////////
// ARENA
#define C_ARENA_MIN			500	

#define C_ARENA_QUERY_REQUEST           500     // 竞技场查询请求
// [sn, playerid]

#define C_ARENA_QUERY_RESPOND           501     // 竞技场查询返回
// [sn, result, [pos, id]]

#define C_ARENA_ATTACK_REQUEST          502     // 竞技场攻击请求
// [sn, pos]

#define C_ARENA_ATTACK_RESPOND          503     // 竞技场攻击返回 
// [sn, result, [pos, id, name, level], fightid, winner, newpos]

#define C_ARENA_JOIN_REQUEST		504	// 加入竞技场请求
// [sn]
#define C_ARENA_JOIN_RESPOND		505	// 加入竞技场返回
// [sn, result, [pos, ...], [[pos id, name, level], ...], [[fightinfo], ...]

#define C_ARENA_REWARD_REQUEST		506	// 领取竞技场奖励请求
// [sn]
#define C_ARENA_REWARD_RESPOND		507	// 领取竞技场奖励放回
// [sn, result, count, prestige]

#define C_ARENA_RESET_CD_REQUEST	508	// 清除竞技场cd请求
// [sn]

#define C_ARENA_RESET_CD_RESPOND	509	// 清除竞技场cd返回
// [sn, result]

#define C_ARENA_MAX			599

////////////////////////////////////////////////////////////////////////////////
// GUILD
#define C_GUILD_MIN			300

#define C_GUILD_QUERY_REQUEST           300     //查询军团请求
//[sn, guildid]
#define C_GUILD_QUERY_RESPOND           301     //查询军团返回
//[sn,result,guildid,name,grade,rank,people,qq,exp,功勋,公告]

#define C_GUILD_CREATE_REQUEST          302     //创建军团请求
//[sn, name]
#define C_GUILD_CREATE_RESPOND          303     //创建军团返回
//[sn, Command.RET_SUCCESS, guild.id]


#define C_GUILD_JOIN_REQUEST            304     //加入军团请求
// [sn, gid]
#define C_GUILD_JOIN_RESPOND            305     //加入军团返回
// [sn, result, "success"/"failed"]

#define C_GUILD_LEAVE_REQUEST           306     //脱离军团请求
//[sn]
#define C_GUILD_LEAVE_RESPOND           307     //脱离军团返回
//[sn, result, "success"/"failed"]

#define C_GUILD_QUERY_GUILD_LIST_REQUEST        308     //查询军团列表请求
//[sn]    
#define C_GUILD_QUERY_GUILD_LIST_RESPOND        309	 //查询军团列表返回
//[sn, ret, [guild.id, guild.name, guild.leader.id, guild.leader.name, guild.mcount], ...]

#define C_GUILD_QUERY_MEMBERS_REQUEST     310     //查询军团成员列表请求
//[sn]
#define C_GUILD_QUERY_MEMBERS_RESPOND     311     //查询军团成员列表返回
//[sn, ret, [m.id, m.name, m.level], ...]

//#define C_GUILD_QUERY_LOG_REQUEST         312	//查询军团日志请求
//[sn,guild,pos,length,max]
//#define C_GUILD_QUERY_LOG_RESPOND         313	//查询军团日志返回
//[sn,result,guild,pos,[[log,time],...]]

//#define C_GUILD_QUERY_ACTIVITIES_REQUEST  314	//查询军团活动请求
//[sn,guild]
//#define C_GUILD_QUERY_ACTIVITIES_RESPOND  315	//查询军团活动返回
//[sn,guild,[[activityId,state,...],...]]

#define C_GUILD_QUERY_APPLY_REQUEST       316	//查询军团申请列表请求
//[sn]
#define C_GUILD_QUERY_APPLY_RESPOND       317	//查询军团申请列表返回
//[sn, ret, [playerid, name, level], ...];

#define C_GUILD_AUDIT_REQUEST             318	//军团审核请求
//[sn, playerid, type] type:1 同意， 2 不同意
#define C_GUILD_AUDIT_RESPOND             319	//军团审核返回
//[sn, result, "success"/"failed"]

#define C_GUILD_SETTING_REQUEST           320	//军团设置请求
//[sn, notice]
#define C_GUILD_SETTING_RESPOND           321	//军团设置返回
//[sn, result, "success"/"failed"]

#define C_GUILD_TRANSFER_REQUEST          322	//军团转让请求 【转让和职位设置可以合并到一起】
//[sn,id]
#define C_GUILD_TRANSFER_RESPOND          323	//军团转让返回
//[sn,result,id]

//#define C_GUILD_SETPOS_REQUEST            324	//军团职位设置(目前只是副军团长)请求
//[sn,id,type] type:1 提升为副军团长，2 降级为普通成员
//#define C_GUILD_SETPOS_RESPOND            325	//军团职位设置(目前只是副军团长)返回
//[sn,result,id,type]

//#define C_GUILD_DISSOLVE_REQUEST          326	//解散军团请求
//[sn]
//#define C_GUILD_DISSOLVE_RESPOND          327	//解散军团返回
//[sn,result,guildname]

#define C_GUILD_QUEYR_BY_PLAYER_REQUEST	  328	// 查询玩家所属军团请求
//[sn, playerid]
#define C_GUILD_QUEYR_BY_PLAYER_RESPOND	  329	// 查询玩家所属军团返回
//[sn,result,[pid,title],[gid,...]]  guildid = 0 表示没有军团

#define C_GUILD_SET_TITLE_REQUEST	330 	// 设置头衔请求
#define C_GUILD_SET_TITLE_RESPOND	331 	// 设置头衔返回
#define C_GUILD_INVITE_REQUEST		332    	// 邀请加入请求
#define C_GUILD_INVITE_RESPOND		333    	// 邀请加入返回

#define C_GUILD_QUERY_PLAYER_REQUEST	334	// 查询军团玩家信息请求
// [sn, playerid]
#define C_GUILD_QUERY_PLAYER_RESPOND	335	// 查询军团玩家信息返回
// [sn, pid, gid, [title, ...]]

#define C_GUILD_SET_LEADER_REQUEST	336	// 设置军团长请求
// [sn, playerid]
#define C_GUILD_SET_LEADER_RESPOND	337	// 设置军团长返回
// [sn, result, playerid]

#define C_GUILD_QUERY_BY_TITLE_REQUEST	338	// 通过职位查询角色请求
// [sn, title]

#define C_GUILD_QUERY_BY_TITLE_RESPOND	339	// 通过职位查询角色返回
// [sn, result, [playerid, name, level], ...]

#define C_GUILD_KICK_REQUEST		340	// 踢人请求
// [sn, playerid]
#define C_GUILD_KICK_RESPOND		341	// 踢人返回
// [sn, result, playerid]

#define C_GUILD_CLEAN_ALL_REQUEST        342     // 清除所有申请请求
// [sn]
#define C_GUILD_CLEAN_ALL_RESPOND        343     // 清除所有申请请求
// [sn, result]

#define S_GUILD_QUERY_BY_PLAYER_REQUEST	390 // 查询玩家所属军团请求
// GuildQueryByPlayerRequest 

#define S_GUILD_QUERY_BY_PLAYER_RESPOND	391 // 查询玩家所属军团返回
// GuildQueryByPlayerRespond 

#define S_GUILD_ADD_EXP_REQUEST 392  // 增加军团经验请求
// PGuildAddExpRequest 

#define S_GUILD_ADD_EXP_RESPOND 393  // 增加军团经验返回
// aGameRespond;

#define C_GUILD_MAX			  399


////////////////////////////////////////////////////////////////////////////////
// 
#define C_I_AM_GOD_REQEUST		1000	//重置cd和资源最大化请求
// [sn]
#define C_I_AM_GOD_RESPOND		1001	//重置cd和资源最大化返回
// [sn, result, info]

#define C_CALL_SCRIPT_REQUEST		1002	// 调用脚本请求
// [sn, func, param, ...]
#define C_CALL_SCRIPT_RESPOND		1003	// 调用脚本返回
// [sn, result]
//
#define S_SERVICE_REGISTER_REQUEST	1004	// 注册服务
// ServiceRegisterRequest 
#define S_SERVICE_REGISTER_RESPOND	1005	// 注册服务
// ServiceRegisterRespond 

#define S_SERVICE_BROADCAST_REQUEST	1006	// 服务广播
// ServiceBroadcastRequest
#define S_SERVICE_BROADCAST_RESPOND	1007	
// ServiceBroadcastRespond 

#define C_GET_SERVICE_STATUS_REQUEST	1008	// 获取在线服务
// [sn]

#define C_GET_SERVICE_STATUS_RESPOND	1009	
// [sn, result, id, ...]

#define S_ADMIN_ADD_ACTIVITY_INFO_REQUEST 1010  // 增加活跃度
// PAdminAddActivityInfoRequest
#define S_ADMIN_ADD_ACTIVITY_INFO_RESPOND 1011
// aGameRespond

#define S_ADMIN_ADD_VIP_EXP_REQUEST 1012
// PAdminAddVIPExpRequest
#define S_ADMIN_ADD_VIP_EXP_RESPOND 1013
// aGameRespond

#define S_PLAYER_CHANGE_NOTIFY		1100	// SPlayerChangeNotify
// #define S_PLAYER_CHANGE_NOTIFY		3023	// aGameRespond


// #define S_RUN_SCRIPT_REQUEST 		1010	// 执行脚本请求 RunScriptRequest 
// #define S_RUN_SCRIPT_RESPOND 		1011	// 执行脚本返回 aGameRespond

////////////////////////////////////////////////////////////////////////////////
// CHAT
#define C_JOIN_CHANNEL_REQUEST		2001
// [sn, name, country, guildid, chanel, ...]

#define C_JOIN_CHANNEL_RESPOND		2002
// [sn, result, info]

#define C_LEAVE_CHANNEL_REQUEST		2003
// [sn]

#define C_LEAVE_CHANNEL_RESPOND		2004
// [sn, result, info]

#define C_CHAT_MESSAGE_REQUEST		2005	//聊天信息请求
#define 	CHAT_WORLD		   1    
#define 	CHAT_COUNTRY		   2	
#define 	CHAT_GUILD		   3	
#define 	CHAT_SYSTEM		   4    
//[sn, to, message]

#define C_CHAT_MESSAGE_RESPOND		2006	// 聊天信息返回
//[sn, result, info]

#define C_CHAT_MESSAGE_NOTIFY		2007	// 聊天信息通知
//[sn, [fromid, fromname], to, message]

#define S_CHAT_MESSAGE_REQUEST		2900 	// 系统发送聊天信息
// ChatMessageRequest
#define S_CHAT_MESSAGE_RESPOND		2901	// 系统发送聊天信息
// ChatMessageRespond

#define S_RECORD_NOTIRY_MESSAGE_REQUEST 2902 	// 发送离线通知请求
// RecordNotifyMessageRequest

#define S_RECORD_NOTIRY_MESSAGE_RESPOND 2903 	// 发送离线通知返回
// RecordNotifyMessageRespond

#define S_TIMING_NOTIFY_ADD_REQUEST	2904 // 增 计时广播
#define S_TIMING_NOTIFY_ADD_RESPOND	2905

#define S_TIMING_NOTIFY_QUERY_REQUEST	2906 // 查 计时广播
#define S_TIMING_NOTIFY_QUERY_RESPOND	2907

#define S_TIMING_NOTIFY_DEL_REQUEST	2908 // 删 计时广播
#define S_TIMING_NOTIFY_DEL_RESPOND	2909

#define S_ADMIN_ADD_MAIL_REQUEST	2910 // 填加邮件
#define S_ADMIN_ADD_MAIL_RESPOND	2911

#define S_ADMIN_QUERY_MAIL_REQUEST	2912 // 查询邮件
#define S_ADMIN_QUERY_MAIL_RESPOND	2913

#define S_ADMIN_DEL_MAIL_REQUEST	2914 // 删除邮件
#define S_ADMIN_DEL_MAIL_RESPOND	2915


////////////////////////////////////////////////////////////////////////////////
// SERVER
#define S_GET_PLAYER_ARMY_REQUEST	3001	// PGetPlayerArmyRequest
#define S_GET_PLAYER_ARMY_RESPOND	3002	// PGetPlayerArmyRespond
#define S_FIGHT_NOTIFICATION  		3003	// FightNotification
#define S_GET_PLAYER_INFO_REQUEST       3004	// PGetPlayerInfoRequest
#define S_GET_PLAYER_INFO_RESPOND       3005    // PGetPlayerInfoRespond
#define S_ADD_PLAYER_NOTIFICATION_REQUEST	3006 // PAddPlayerNotificationRequest 
#define S_ADD_PLAYER_NOTIFICATION_RESPOND	3007 // PAddPlayerNotificationRespond
#define S_ADMIN_REWARD_REQUEST		3008	//PAdminRewardRequest
#define S_ADMIN_REWARD_RESPOND		3009	//PAdminAddExpRespond
#define 	REWARD_PLAYER_EXP	1
#define 	REWARD_PLAYER_PRESTIGE	2
#define 	REWARD_RESOURCES_VALUE	3
#define 	REWARD_HERO_EXP_SPEC	4
#define 	REWARD_ITEM		5
#define 	REWARD_GEM		6
#define 	REWARD_EQUIP		7
#define 	REWARD_HERO_ID		10
#define S_SET_PLAYER_LOCATION_REQUEST		3010	//PSetPlyaerLocationRequest
#define S_SET_PLAYER_LOCATION_RESPOND		3011	//PSetPlyaerLocationRespond
#define S_GET_PLAYER_STORY_REQUEST		3012	//PGetPlayerStoryRequset
#define S_GET_PLAYER_STORY_RESPOND		3013	//PGetPlayerStoryRespond
#define S_SET_PLAYER_STATUS_REQUEST		3014	//PSetPlayerStatusRequset
#define S_SET_PLAYER_STATUS_RESPOND		3015	//PSetPlayerStatusRespond
#define         PLAYER_STATUS_NORMAL		0x00	//正常
#define         PLAYER_STATUS_BAN		0x01	//封号
#define         PLAYER_STATUS_MUTE		0x02	//禁言

#define S_ADMIN_PLAYER_KICK_REQUEST		3016	//PAdminPlayerKickRequest
#define S_ADMIN_PLAYER_KICK_RESPOND		3017	//PAdminPlayerKickRespond

#define S_GET_PLAYER_BUILDING_REQUEST	3018	// PGetPlayerBuildingRequest
#define S_GET_PLAYER_BUILDING_RESPOND	3019	// PGetPlayerBuildingRespond

#define S_GET_PLAYER_TECHNOLOGY_REQUEST	3020	// PGetPlayerTechnologyRequest
#define S_GET_PLAYER_TECHNOLOGY_RESPOND	3021	// PGetPlayerTechnologyRespond

#define S_ADMIN_SET_ADULT_REQUEST	3022	// PAdminSetAdultRequest
#define S_ADMIN_SET_ADULT_RESPOND	3023	// aGameRespond

#define S_ADMIN_SET_CARD_REQUEST 3024		// PAdminSetCard
#define S_ADMIN_SET_CARD_RESPOND 3025		// aGameRespond


////////////////////////////////////////////////////////////////////////////////
// BATTLEFIELD
#define C_BATTLEFIELD_JOIN_REQUEST	4000	// 加入战场请求
#define C_BATTLEFIELD_JOIN_RESPOND	4001	// 加入战场返回

#define C_BATTLEFIELD_LEAVE_REQUEST	4002	// 离开战场请求
#define C_BATTLEFIELD_LEAVE_RESPOND	4003	// 离开战场返回

////////////////////////////////////////////////////////////////////////////////
// mail

#define MAIL_TYPE_NORMAL		0x01	// 普通邮件
#define MAIL_TYPE_MESSAGE		0x02	// 点对点消息
#define MAIL_TYPE_NOTIFICATION		0x04	// 通知消息

#define MAIL_STATUS_UNREAD		0x01	// 未读
#define MAIL_STATUS_READ		0x02	// 已读

#define C_MAIL_MIN			5000
#define C_MAIL_QUERY_REQUEST		5001	// 查询邮件列表请求
// [sn, type, status]  过滤器  type: 邮件类型  status 邮件状态

#define C_MAIL_QUERY_RESPOND		5002	// 查询邮件列表返回
// [sn, result, [id, type, title, status, [fromid, fromname]], ...]

#define C_MAIL_GET_REQUEST		5003	// 获取邮件内容请求
// [sn, id, ...]

#define C_MAIL_GET_RESPOND		5004	// 获取邮件内容返回
// [sn, result, [id, type, title, content], ...]

#define C_MAIL_MARK_REQUEST		5005	// 标记已读/未读请求
// [sn, [id, status], ...]

#define C_MAIL_MARK_RESPOND		5006	// 标记已读/未读返回
// [sn, result, [id, status], ...]

#define C_MAIL_DEL_REQUEST		5007	// 删除邮件请求
// [sn, id, ...]

#define C_MAIL_DEL_RESPOND		5008	// 删除邮件返回
// [sn, id, ...]

#define C_MAIL_SEND_REQUEST		5009	// 发送邮件请求
// [sn, to, type, title, content]

#define C_MAIL_SEND_RESPOND		5010	// 发送邮件返回
// [sn, result]

#define C_MAIL_CONTACT_GET_REQUEST	5011	// 获取联系人列表请求
// [sn]

#define C_MAIL_CONTACT_GET_RESPOND	5012	// 获取联系人列表返回
// [sn, result, [id, type, name], ...]

#define C_MAIL_CONTACT_ADD_REQUEST	5013	// 添加联系人列表请求
// [sn, type,  id]

#define C_MAIL_CONTACT_ADD_RESPOND	5014	// 添加联系人请求列表
// [sn, type, id, name]

#define C_MAIL_CONTACT_DEL_REQUEST	5015	// 删除联系人请求
// [sn, id]

#define C_MAIL_CONTACT_DEL_RESPOND	5016	// 删除联系人返回
// [sn, id]

#define C_MAIL_GET_NOTIRY_MESSAGE_REQUEST 5017	// 查询玩家已存储通知信息请求
// [sn]

#define C_MAIL_GET_NOTIRY_MESSAGE_RESPOND 5018	// 查询玩家已存储通知信息返回
// [sn, result]

#define S_MAIL_CONTACT_GET_REQUEST 5901	// 查询好友列表请求
// MailContactGetRequest 

#define S_MAIL_CONTACT_GET_RESPOND 5902	// 查询好友列表返回
// MailContactGetRespond 

#define C_MAIL_MAX			5999

#pragma pack(pop)

#endif
