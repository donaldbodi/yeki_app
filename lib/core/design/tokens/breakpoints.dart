import 'package:flutter/widgets.dart';

/// Points de rupture responsive — CDC_DESIGN §4.1.
///
/// Aucun écran ne teste `MediaQuery.of(context).size.width > 700` en dur :
/// il appelle [YkBreakpoints.of] qui renvoie une énumération.
enum YkBreakpoint {
  /// < 600 px — téléphone portrait.
  compact,

  /// 600–904 px — téléphone paysage, petite tablette.
  medium,

  /// 905–1239 px — tablette, petite fenêtre desktop.
  expanded,

  /// 1240–1599 px — desktop, web.
  large,

  /// ≥ 1600 px — grand écran, TV, moniteur pro.
  xlarge,
}

class YkBreakpoints {
  YkBreakpoints._();

  static const double medium = 600;
  static const double expanded = 905;
  static const double large = 1240;
  static const double xlarge = 1600;

  static YkBreakpoint of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return fromWidth(width);
  }

  static YkBreakpoint fromWidth(double width) {
    if (width < medium) return YkBreakpoint.compact;
    if (width < expanded) return YkBreakpoint.medium;
    if (width < large) return YkBreakpoint.expanded;
    if (width < xlarge) return YkBreakpoint.large;
    return YkBreakpoint.xlarge;
  }
}
