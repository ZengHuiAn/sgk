using UnityEngine;
using UnityEngine.UI;
using VoxelBusters.NativePlugins;
using System.Collections;
using System.Collections.Generic;

namespace SGK
{
    public class NotificationCenter : MonoBehaviour
    {
        Dictionary<string, System.Action> Launchcallbacks = new Dictionary<string, System.Action>();
        Dictionary<string, System.Action> Receivecallbacks = new Dictionary<string, System.Action>();
        private void Start()
        {
            NPBinding.NotificationService.ClearNotifications();
            NPBinding.NotificationService.CancelAllLocalNotification();
            NPBinding.NotificationService.RegisterNotificationTypes(NotificationType.Alert | NotificationType.Badge | NotificationType.Sound);
            //NPBinding.NotificationService.RegisterNotificationTypes(NotificationType.Alert | NotificationType.Sound);
        }
        public void Test()
        {
            Debug.Log("测试试");
            AddNotification(10, "开始");
        }
        private void OnEnable()
        {
            // Register for callbacks
            NotificationService.DidLaunchWithLocalNotificationEvent += DidLaunchWithLocalNotificationEvent;
            NotificationService.DidReceiveLocalNotificationEvent += DidReceiveLocalNotificationEvent;
        }

        private void OnDisable()
        {
            // Un-Register from callbacks
            NotificationService.DidLaunchWithLocalNotificationEvent -= DidLaunchWithLocalNotificationEvent;
            NotificationService.DidReceiveLocalNotificationEvent -= DidReceiveLocalNotificationEvent;
        }

        public string AddNotificationWithTime(int hour, string content)
        {
            System.DateTime date = new System.DateTime(System.DateTime.Now.Year, System.DateTime.Now.Month, System.DateTime.Now.Day, hour, 0, 0);
            return ScheduleLocalNotification(CreateNotification(date, content, eNotificationRepeatInterval.NONE));
        }
        public string AddNotification(long _fireAfterSec, string content)
        {
            return ScheduleLocalNotification(CreateNotification(System.DateTime.Now.AddSeconds(_fireAfterSec), content, eNotificationRepeatInterval.NONE));
        }
        public string AddNotification(long _fireAfterSec, string content, eNotificationRepeatInterval _repeatInterval)
        {
            return ScheduleLocalNotification(CreateNotification(System.DateTime.Now.AddSeconds(_fireAfterSec), content, _repeatInterval));
        }

        public void AddLaunchCallbacks(string id, System.Action func)
        {
            if (func != null)
            {
                Launchcallbacks[id] = func;
            }
        }

        public void AddReceiveCallbacks(string id, System.Action func)
        {
            if (func != null)
            {
                Receivecallbacks[id] = func;
            }
        }

        private CrossPlatformNotification CreateNotification(System.DateTime _date, string content, eNotificationRepeatInterval _repeatInterval)
        {
            // User info
            IDictionary _userInfo = new Dictionary<string, string>();
            _userInfo["data"] = "custom data";

            CrossPlatformNotification.iOSSpecificProperties _iosProperties = new CrossPlatformNotification.iOSSpecificProperties();
            _iosProperties.HasAction = true;
            _iosProperties.AlertAction = content;

            CrossPlatformNotification.AndroidSpecificProperties _androidProperties = new CrossPlatformNotification.AndroidSpecificProperties();
            _androidProperties.ContentTitle = Application.productName; // "银之守墓人";
            _androidProperties.TickerText = content;
            _androidProperties.LargeIcon = "hualing.png"; //Keep the files in Assets/PluginResources/Android or Common folder.

            CrossPlatformNotification _notification = new CrossPlatformNotification();
            _notification.AlertBody = content; //On Android, this is considered as ContentText
            _notification.FireDate = _date;
            _notification.RepeatInterval = _repeatInterval;
            _notification.SoundName = ""; //Keep the files in Assets/PluginResources/Android or iOS or Common folder.
            _notification.UserInfo = _userInfo;
            _notification.iOSProperties = _iosProperties;
            _notification.AndroidProperties = _androidProperties;

            return _notification;
        }

        private void DidLaunchWithLocalNotificationEvent(CrossPlatformNotification _notification)
        {
            string id = _notification.GetNotificationID();
            System.Action _callback;
            if (Launchcallbacks.TryGetValue(id, out _callback))
            {
                _callback();
                if (_notification.RepeatInterval == eNotificationRepeatInterval.NONE)
                {
                    Launchcallbacks.Remove(id);
                }
            }
            Debug.Log("!!!!!!!!!!!!!!!!!DidLaunchWithLocalNotificationEvent");
        }

        private void DidReceiveLocalNotificationEvent(CrossPlatformNotification _notification)
        {
            string id = _notification.GetNotificationID();
            System.Action _callback;
            if (Receivecallbacks.TryGetValue(id, out _callback))
            {
                _callback();
                if (_notification.RepeatInterval == eNotificationRepeatInterval.NONE)
                {
                    Receivecallbacks.Remove(id);
                }       
            }
            Debug.Log("!!!!!!!!!!!!!!!!!DidReceiveLocalNotificationEvent");
        }

        private void RegisterNotificationTypes(NotificationType _notificationTypes)
        {
            NPBinding.NotificationService.RegisterNotificationTypes(_notificationTypes);
        }

        private NotificationType EnabledNotificationTypes()
        {
            return NPBinding.NotificationService.EnabledNotificationTypes();
        }

        private void RegisterForRemoteNotifications()
        {
            NPBinding.NotificationService.RegisterForRemoteNotifications();
        }

        private void UnregisterForRemoteNotifications()
        {
            NPBinding.NotificationService.UnregisterForRemoteNotifications();
        }

        private string ScheduleLocalNotification(CrossPlatformNotification _notification)
        {
            return NPBinding.NotificationService.ScheduleLocalNotification(_notification);
        }

        public void CancelLocalNotification(string _notificationID)
        {
            if (Receivecallbacks[_notificationID] != null)
            {
                Receivecallbacks.Remove(_notificationID);
            }
            if (Launchcallbacks[_notificationID] != null)
            {
                Launchcallbacks.Remove(_notificationID);
            }
            NPBinding.NotificationService.CancelLocalNotification(_notificationID);
        }

        public void CancelAllLocalNotifications()
        {
            Launchcallbacks.Clear();
            Receivecallbacks.Clear();
            NPBinding.NotificationService.CancelAllLocalNotification();
        }

        public void ClearNotifications()
        {
            NPBinding.NotificationService.ClearNotifications();
        }

    }
}
