using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace SGK {
	namespace Localization {
		public static class ShortcutExtensions {
			public static void TextFormat(this Text target, string fmt, params object [] args) {
				target.text = ((args == null) ? fmt : string.Format(fmt, args));
			}

			public static void TextFormat(this GameObject target, string fmt, params object [] args) {
				Text text = target.GetComponent<Text>();
				text.TextFormat(fmt, args);
			}
		}
	}
}
