import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stoyco_shared/form/extensions/datetime_extension.dart';
import 'package:vph_common_widgets/vph_common_widgets.dart';

const _kSlideTransitionDuration = Duration(milliseconds: 300);
const _kActionHeight = 36.0;

/// Shows a dialog containing a date picker.
///
/// The returned [Future] resolves to the date selected by the user when the
/// user confirms the dialog. If the user cancels the dialog, null is returned.
///
/// When the date picker is first displayed, it will show the month of
/// [initialDate], with [initialDate] selected.
///
/// The [firstDate] is the earliest allowable date. The [lastDate] is the latest
/// allowable date. [initialDate] must either fall between these dates,
/// or be equal to one of them
///
/// The [width] define the width of date picker dialog
///
Future<DateTime?> showWebDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  double? width,
  bool? withoutActionButtons,
  Color? weekendDaysColor,
  double? pickerWidth,
  double? pickerHeight,
}) {
  return showPopupDialog(
    context,
    (context) => _WebDatePicker(
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(0),
      lastDate: lastDate ?? DateTime(100000),
      withoutActionButtons: withoutActionButtons ?? false,
      weekendDaysColor: weekendDaysColor,
      pickerWidth: pickerWidth,
      pickerHeight: pickerHeight,
    ),
    asDropDown: true,
    useTargetWidth: width != null ? false : true,
    dialogWidth: width,
  );
}

class _WebDatePicker extends StatefulWidget {
  const _WebDatePicker({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.withoutActionButtons,
    this.weekendDaysColor,
    this.pickerWidth,
    this.pickerHeight,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final bool withoutActionButtons;
  final Color? weekendDaysColor;
  final double? pickerWidth;
  final double? pickerHeight;

  @override
  State<_WebDatePicker> createState() => _WebDatePickerState();
}

class _WebDatePickerState extends State<_WebDatePicker> {
  late DateTime _selectedDate;
  late DateTime _startDate;

  double _slideDirection = 1.0;
  _PickerViewMode _viewMode = _PickerViewMode.day;
  bool _isViewModeChanged = false;
  Size? _childSize;

  @override
  void initState() {
    super.initState();
    _selectedDate = _startDate = widget.initialDate;
  }

  List<Widget> _buildDaysOfMonthCells(ThemeData theme) {
    final textStyle =
        theme.textTheme.bodySmall?.copyWith(color: const Color(0xff1C197F));
    final now = DateTime.now();
    final monthDateRange =
        _startDate.monthDateTimeRange(includeTrailingAndLeadingDates: true);
    final children = kWeekdayAbbreviations
        .asMap()
        .entries
        .map<Widget>(
          (e) => Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(e.value,
                style: e.key == 0 || e.key == (kWeekdayAbbreviations.length - 1)
                    ? widget.weekendDaysColor != null
                        ? textStyle?.copyWith(color: widget.weekendDaysColor)
                        : textStyle
                    : textStyle),
          ),
        )
        .toList();
    for (int i = 0; i < kNumberCellsOfMonth; i++) {
      final date = monthDateRange.start.add(Duration(days: i));
      if (_startDate.month == date.month) {
        final isEnabled = (date.dateCompareTo(widget.firstDate) >= 0) &&
            (date.dateCompareTo(widget.lastDate) <= 0);
        final isSelected = date.dateCompareTo(_selectedDate) == 0;
        final isNow = date.dateCompareTo(now) == 0;
        final isWeekend = date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday;
        final color = isEnabled
            ? const Color(0xff1C197F)
            : const Color(0xff1C197F).withOpacity(0.5);
        final cellTextStyle = isSelected
            ? textStyle?.copyWith(color: Colors.white)
            : isEnabled
                ? isWeekend && widget.weekendDaysColor != null
                    ? textStyle?.copyWith(color: widget.weekendDaysColor)
                    : textStyle
                : textStyle?.copyWith(
                    color: isWeekend && widget.weekendDaysColor != null
                        ? widget.weekendDaysColor?.withOpacity(0.5)
                        : Colors.black.withOpacity(0.3));
        Widget child = Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? color : null,
            border: isNow && !isSelected ? Border.all(color: color) : null,
          ),
          child: Text(date.day.toString(), style: cellTextStyle),
        );
        if (isEnabled) {
          child = InkWell(
            onTap: () => setState(() => _selectedDate = date),
            customBorder: const CircleBorder(),
            child: child,
          );
        }
        children.add(Padding(padding: const EdgeInsets.all(2.0), child: child));
      } else {
        children.add(Container());
      }
    }
    return children;
  }

  List<Widget> _buildMonthsOfYearCells(ThemeData theme) {
    final textStyle =
        theme.textTheme.bodySmall?.copyWith(color: const Color(0xff1C197F));
    final borderRadius = BorderRadius.circular(_childSize!.height / 4 - 32);
    final children = <Widget>[];
    final now = DateTime.now();
    for (int i = 1; i <= kNumberOfMonth; i++) {
      final date = DateTime(_startDate.year, i);
      final isEnabled = (date.monthCompareTo(widget.firstDate) >= 0) &&
          (date.monthCompareTo(widget.lastDate) <= 0);
      final isSelected = date.monthCompareTo(_selectedDate) == 0;
      final isNow = date.monthCompareTo(now) == 0;

      Widget child = Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff1C197F).withOpacity(0.6) : null,
          border: isNow && !isSelected
              ? Border.all(color: const Color(0xff1C197F))
              : null,
          borderRadius: borderRadius,
        ),
        child: Text(
          kMonthShortNames[i - 1],
          style: isSelected
              ? textStyle?.copyWith(color: Colors.white)
              : isEnabled
                  ? textStyle
                  : textStyle?.copyWith(color: const Color(0xff1C197F)),
        ),
      );
      if (isEnabled) {
        child = InkWell(
          onTap: () => _onViewModeChanged(next: false, date: date),
          borderRadius: borderRadius,
          child: child,
        );
      }
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: child,
        ),
      );
    }
    return children;
  }

  List<Widget> _buildYearsCells(ThemeData theme) {
    final textStyle =
        theme.textTheme.bodySmall?.copyWith(color: const Color(0xff1C197F));
    final borderRadius = BorderRadius.circular(_childSize!.height / 5 - 16);
    final children = <Widget>[];
    final now = DateTime.now();
    final year = _startDate.year - _startDate.year % 20;
    for (int i = 0; i < 20; i++) {
      final date = DateTime(year + i);
      final isEnabled = (date.year >= widget.firstDate.year) &&
          (date.year <= widget.lastDate.year);
      final isSelected = date.year == _selectedDate.year;
      final isNow = date.year == now.year;
      final color = isEnabled
          ? theme.colorScheme.primary
          : theme.colorScheme.primary.withOpacity(0.5);
      Widget child = Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff1C197F).withOpacity(0.6) : null,
          border: isNow && !isSelected ? Border.all(color: color) : null,
          borderRadius: borderRadius,
        ),
        child: Text(
          (year + i).toString(),
          style: isSelected
              ? textStyle?.copyWith(color: Colors.white)
              : isEnabled
                  ? textStyle
                  : textStyle?.copyWith(color: Colors.black.withOpacity(0.3)),
        ),
      );

      if (isEnabled) {
        child = InkWell(
          onTap: () => _onViewModeChanged(next: false, date: date),
          borderRadius: borderRadius,
          child: child,
        );
      }
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: child,
        ),
      );
    }
    return children;
  }

  List<Widget> _buildYearsOfCenturyCells(ThemeData theme) {
    final textStyle = theme.textTheme.bodySmall?.copyWith(color: Colors.black);
    final borderRadius = BorderRadius.circular(_childSize!.height / 5 - 16);
    final children = <Widget>[];
    final now = DateTime.now();
    final year = _startDate.year - _startDate.year % 200;
    for (int i = 0; i < 10; i++) {
      final date = DateTime(year + i * 20);
      final isEnabled = (widget.firstDate.year <= date.year ||
              (widget.firstDate.year - date.year) <= 20) &&
          (date.year + 20 <= widget.lastDate.year ||
              (date.year - widget.lastDate.year) <= 0);
      final isSelected = _selectedDate.year >= date.year &&
          (_selectedDate.year - date.year) < 20;
      final isNow = now.year >= date.year && (now.year - date.year) < 20;
      final color = isEnabled
          ? theme.colorScheme.primary
          : theme.colorScheme.primary.withOpacity(0.5);
      Widget child = Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff1C197F).withOpacity(0.6) : null,
          border: isNow && !isSelected ? Border.all(color: color) : null,
          borderRadius: borderRadius,
        ),
        child: Text(
          "${date.year} - ${date.year + 19}",
          style: isSelected
              ? textStyle?.copyWith(color: Colors.white)
              : isEnabled
                  ? textStyle
                  : textStyle?.copyWith(color: Colors.black.withOpacity(0.3)),
        ),
      );
      if (isEnabled) {
        child = InkWell(
          onTap: () => _onViewModeChanged(next: false, date: date),
          borderRadius: borderRadius,
          child: child,
        );
      }
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: child,
        ),
      );
    }
    return children;
  }

  Widget _buildChild(ThemeData theme) {
    switch (_viewMode) {
      case _PickerViewMode.day:
        return UniformGrid(
          key: _PickerKey(date: _startDate, viewMode: _viewMode),
          columnCount: kNumberOfWeekday,
          squareCell: true,
          onSizeChanged: _onSizeChanged,
          children: _buildDaysOfMonthCells(theme),
        );
      case _PickerViewMode.month:
        return UniformGrid(
          key: _PickerKey(date: _startDate, viewMode: _viewMode),
          columnCount: 3,
          withHeader: false,
          fixedSize: _childSize,
          children: _buildMonthsOfYearCells(theme),
        );
      case _PickerViewMode.year:
        return UniformGrid(
          key: _PickerKey(date: _startDate, viewMode: _viewMode),
          columnCount: 4,
          withHeader: false,
          fixedSize: _childSize,
          children: _buildYearsCells(theme),
        );
      case _PickerViewMode.century:
        return UniformGrid(
          key: _PickerKey(date: _startDate, viewMode: _viewMode),
          columnCount: 2,
          withHeader: false,
          fixedSize: _childSize,
          children: _buildYearsOfCenturyCells(theme),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget navTitle;
    bool isFirst = false, isLast = false, nextView = true;
    switch (_viewMode) {
      case _PickerViewMode.day:
        navTitle = Container(
          height: _kActionHeight,
          alignment: Alignment.center,
          child: Text(
            "${kMonthNames[_startDate.month - 1]} ${_startDate.year}",
            style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xff1C197F), fontWeight: FontWeight.bold),
          ),
        );
        final monthDateRange = _startDate.monthDateTimeRange(
            includeTrailingAndLeadingDates: false);
        isFirst = widget.firstDate.dateCompareTo(monthDateRange.start) >= 0;
        isLast = widget.lastDate.dateCompareTo(monthDateRange.end) <= 0;
        nextView = widget.lastDate.difference(widget.firstDate).inDays > 28;
        break;
      case _PickerViewMode.month:
        navTitle = Container(
          height: _kActionHeight,
          alignment: Alignment.center,
          child: Text(
            _startDate.year.toString(),
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        );
        isFirst = _startDate.year <= widget.firstDate.year;
        isLast = _startDate.year >= widget.lastDate.year;
        nextView = widget.lastDate.year != widget.firstDate.year;
        break;
      case _PickerViewMode.year:
        final year = _startDate.year - _startDate.year % 20;
        isFirst = year <= widget.firstDate.year;
        isLast = year + 20 >= widget.lastDate.year;
        navTitle = Container(
          height: _kActionHeight,
          alignment: Alignment.center,
          child: Text(
            "$year - ${year + 19}",
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        );
        nextView = widget.lastDate.year - widget.firstDate.year > 20;
        break;
      case _PickerViewMode.century:
        final year = _startDate.year - _startDate.year % 200;
        isFirst = year <= widget.firstDate.year;
        isLast = year + 200 >= widget.lastDate.year;
        navTitle = Container(
          height: _kActionHeight,
          alignment: Alignment.center,
          child: Text(
            "$year - ${year + 199}",
            style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xff1C197F), fontWeight: FontWeight.bold),
          ),
        );
        nextView = false;
        break;
    }
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: widget.pickerWidth ??
            300.0, // Asegura un ancho mínimo si no se especifica uno
        maxWidth: widget.pickerWidth ??
            300.0, // Asegura que el ancho máximo sea igual al mínimo para fijarlo
        minHeight: widget.pickerHeight ?? 400.0, // Asegura un alto mínimo
        maxHeight: widget.pickerHeight ??
            400.0, // Asegura que el alto máximo sea igual al mínimo para fijarlo
      ),
      child: Card(
        margin:
            const EdgeInsets.only(left: 1.0, top: 4.0, right: 1.0, bottom: 2.0),
        elevation: 1.0,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              /// Navigation
              Row(
                children: [
                  isFirst
                      ? SvgPicture.asset(
                          'packages/stoyco_shared/lib/assets/icons/arrow_back.svg',
                          height: 24,
                          width: 24,
                          color: Colors.black.withOpacity(0.3),
                        )
                      : GestureDetector(
                          onTap: () => _onStartDateChanged(next: false),
                          child: SvgPicture.asset(
                            'packages/stoyco_shared/lib/assets/icons/arrow_back.svg',
                            height: 24,
                            width: 24,
                            color: Colors.black,
                          ),
                        ),
                  nextView
                      ? Expanded(
                          child: InkWell(
                            onTap: () => _onViewModeChanged(next: true),
                            borderRadius: BorderRadius.circular(4.0),
                            child: navTitle,
                          ),
                        )
                      : Expanded(child: navTitle),
                  isLast
                      ? RotatedBox(
                          quarterTurns: 2,
                          child: SvgPicture.asset(
                            'packages/stoyco_shared/lib/assets/icons/arrow_back.svg',
                            height: 24,
                            width: 24,
                            color: Colors.black.withOpacity(0.3),
                          ),
                        )
                      : GestureDetector(
                          onTap: () => _onStartDateChanged(next: true),
                          child: RotatedBox(
                            quarterTurns: 2,
                            child: SvgPicture.asset(
                              'packages/stoyco_shared/lib/assets/icons/arrow_back.svg',
                              height: 24,
                              width: 24,
                              color: Colors.black,
                            ),
                          ),
                        )
                ],
              ),

              /// Month view
              ClipRRect(
                child: AnimatedSwitcher(
                  duration: _kSlideTransitionDuration,
                  transitionBuilder: (child, animation) {
                    if (_isViewModeChanged) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    } else {
                      double dx = (child.key as _PickerKey).date == _startDate
                          ? 1.0
                          : -1.0;
                      return SlideTransition(
                        position: Tween<Offset>(
                                begin: Offset(dx * _slideDirection, 0.0),
                                end: const Offset(0.0, 0.0))
                            .animate(animation),
                        child: child,
                      );
                    }
                  },
                  child: _buildChild(theme),
                ),
              ),

              /// Actions
              Row(
                children: [
                  /// Reset
                  if (!widget.withoutActionButtons)
                    _iconWidget(Icons.restart_alt,
                        tooltip: "Reset", onTap: _onResetState),
                  if (!widget.withoutActionButtons) const SizedBox(width: 4.0),

                  /// Today
                  if (!widget.withoutActionButtons)
                    _iconWidget(Icons.today,
                        tooltip: "Today", onTap: _onStartDateChanged),
                  const Spacer(),

                  /// CANCEL
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      "Cancelar",
                      style: TextStyle(color: Color(0xff92929D)),
                    ),
                  ),

                  /// OK
                  if (_viewMode == _PickerViewMode.day) ...[
                    const SizedBox(width: 4.0),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(_selectedDate),
                      child: const Text(
                        "Aceptar",
                        style: TextStyle(color: Color(0xff1C197F)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconWidget(IconData icon,
      {Color? color, String? tooltip, GestureTapCallback? onTap}) {
    final child = Container(
      height: _kActionHeight,
      width: _kActionHeight,
      alignment: Alignment.center,
      child: tooltip != null
          ? Tooltip(message: tooltip, child: Icon(icon, color: color))
          : Icon(icon, color: color),
    );
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: child,
      );
    } else {
      return child;
    }
  }

  void _onStartDateChanged({bool? next}) {
    DateTime date;
    if (next != null) {
      switch (_viewMode) {
        case _PickerViewMode.day:
          date = next ? _startDate.nextMonth : _startDate.previousMonth;
          break;
        case _PickerViewMode.month:
          date = next ? _startDate.nextYear : _startDate.previousYear;
          break;
        case _PickerViewMode.year:
          final year = _startDate.year - _startDate.year % 20;
          date = next ? DateTime(year + 20) : DateTime(year - 20);
          break;
        case _PickerViewMode.century:
          final year = _startDate.year - _startDate.year % 200;
          date = next ? DateTime(year + 200) : DateTime(year - 200);
          break;
      }
    } else {
      final year20 = _startDate.year - _startDate.year % 20;
      final year200 = _startDate.year - _startDate.year % 200;
      date = DateTime.now();
      if (_viewMode == _PickerViewMode.day && date.month == _startDate.month ||
          _viewMode == _PickerViewMode.month && date.year == _startDate.year ||
          _viewMode == _PickerViewMode.year &&
              date.year >= year20 &&
              (date.year - year20) < 20 ||
          _viewMode == _PickerViewMode.century &&
              date.year >= year200 &&
              (date.year - year200) < 200) {
        return;
      }
    }
    setState(
      () {
        _slideDirection = date.isAfter(_startDate) ? 1.0 : -1.0;
        _isViewModeChanged = false;
        _startDate = date;
      },
    );
  }

  void _onViewModeChanged({required bool next, DateTime? date}) {
    setState(() {
      _isViewModeChanged = true;
      _viewMode = next ? _viewMode.next() : _viewMode.previous();
      if (date != null) {
        _startDate = date;
      }
    });
  }

  void _onResetState() {
    setState(
      () {
        _slideDirection = widget.initialDate.isAfter(_startDate) ? 1.0 : -1.0;
        _startDate = widget.initialDate;
        _selectedDate = _startDate;
        _isViewModeChanged = _viewMode != _PickerViewMode.day;
        _viewMode = _PickerViewMode.day;
      },
    );
  }

  void _onSizeChanged(Size size, Size cellSize) {
    _childSize = size;
  }
}

enum _PickerViewMode {
  day,
  month,
  year,
  century;

  _PickerViewMode next() {
    switch (this) {
      case _PickerViewMode.day:
        return _PickerViewMode.month;
      case _PickerViewMode.month:
        return _PickerViewMode.year;
      case _PickerViewMode.year:
        return _PickerViewMode.century;
      case _PickerViewMode.century:
        return _PickerViewMode.century;
    }
  }

  _PickerViewMode previous() {
    switch (this) {
      case _PickerViewMode.day:
        return _PickerViewMode.day;
      case _PickerViewMode.month:
        return _PickerViewMode.day;
      case _PickerViewMode.year:
        return _PickerViewMode.month;
      case _PickerViewMode.century:
        return _PickerViewMode.year;
    }
  }
}

class _PickerKey extends LocalKey {
  const _PickerKey({required this.date, required this.viewMode});

  final DateTime date;
  final _PickerViewMode viewMode;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _PickerKey &&
        other.date == date &&
        other.viewMode == viewMode;
  }

  @override
  int get hashCode => Object.hash(runtimeType, date, viewMode);

  @override
  String toString() {
    return "_PickerKey(date: $date, viewMode: $viewMode)";
  }
}
