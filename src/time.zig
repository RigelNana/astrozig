const angle = @import("angle.zig");
const std = @import("std");
const math = std.math;

pub const CalType = enum {
    Gregorian,
    Julian,
};

pub const Date = struct {
    year: i32,
    month: u8,
    decimalDay: f64,
    calType: CalType,
};

pub const DayOfMonth = struct {
    day: u8,
    hour: u8,
    min: u8,
    sec: f64,
    timeZone: f64,
};

pub const Week = enum {
    Sunday,
    Monday,
    Tuesday,
    Wednesday,
    Thursday,
    Friday,
    Saturday,
};

pub fn weekdayFromDate(date: Date) error{invalidDate}!Week {
    const JD = julianDay(date);
    const day = @mod(@as(i32, @intFromFloat(JD + 1.5)), 7);
    return switch (day) {
        0 => Week.Sunday,
        1 => Week.Monday,
        2 => Week.Tuesday,
        3 => Week.Wednesday,
        4 => Week.Thursday,
        5 => Week.Friday,
        6 => Week.Saturday,
        else => error.invalidDate,
    };
}

pub fn isLeapYear(year: i32, cal_type: CalType) bool {
    switch (cal_type) {
        CalType.Gregorian => {
            return (@rem(year, 4) == 0 and @rem(year, 100) != 0) or @rem(year, 400) == 0;
        },
        CalType.Julian => {
            return @rem(year, 4) == 0;
        },
    }
}

pub inline fn calDecimalDay(day: DayOfMonth) f64 {
    return @as(f64, @floatFromInt(day.day)) + @as(f64, @floatFromInt(day.hour)) / 24.0 + @as(f64, @floatFromInt(day.min)) / (60.0 * 24.0) + day.sec / (60.0 * 60.0 * 24.0) - day.timeZone / 24.0;
}

pub inline fn julianCenturies(JD: f64) f64 {
    return (JD - 2451545.0) / 36525.0;
}

pub inline fn julianMill(JD: f64) f64 {
    return (JD - 2451545.0) / 365250.0;
}

pub fn julianDay(date: Date) f64 {
    const month = date.month;
    const y: f64, const m: f64 =
        if (month <= 2)
        .{ @floatFromInt(date.year - 1), @floatFromInt(month + 12) }
    else
        .{ @floatFromInt(date.year), @floatFromInt(month) };
    const a = @floor(y / 100.0);
    const b = switch (date.calType) {
        CalType.Gregorian => 2.0 - a + @floor(a / 4),
        CalType.Julian => 0.0,
    };
    return @floor(365.25 * (y + 4716.0)) + @floor(30.6001 * (m + 1.0)) + date.decimalDay + b - 1524.5;
}

pub fn dateFromJulianDay(JDc: f64) error{invalidDate}!Date {
    if (JDc < 0.0) {
        return error.invalidDate;
    }
    const JD = JDc + 0.5;
    const Z = @floor(JD);
    const F = JD - Z;
    const alpha = @floor((Z - 1867216.25) / 36524.25);
    const A = if (Z < 2299161.0) Z else Z + 1.0 + alpha - @floor(alpha / 4);
    const B = A + 1524.0;
    const C = @floor((B - 122.1) / 365.25);
    const D = @floor(365.25 * C);
    const E = @floor((B - D) / 30.6001);
    const day = B - D - @floor(30.6001 * E) + F;
    const month: u8 = if (E < 14) @intFromFloat(E - 1) else if (E == 14 or E == 15) @intFromFloat(E - 13) else return error.invalidDate;
    const year: i32 = if (month > 2) @intFromFloat(C - 4716) else if (month == 1 or month == 2) @intFromFloat(C - 4715) else return error.invalidDate;
    return Date{ .year = year, .month = month, .decimalDay = day, .calType = CalType.Gregorian };
}

pub inline fn julianEphemerisDay(JD: f64, delta_T: f64) f64 {
    return delta_T / 86400.0 + JD;
}

pub fn meanSiderealTime(JD: f64) f64 {
    const T = julianCenturies(JD);
    return math.degreesToRadians(angle.limitTo360(280.46061837 + 360.98564736629 * (JD - 2451545.0) + T * T * (0.000387933 - T / 38710000.0)));
}

test "isLeapYear" {
    const year1 = 2020;
    const year2 = 1900;
    const year3 = 2000;
    const year4 = 2001;

    const leap1 = isLeapYear(year1, CalType.Gregorian);
    const leap2 = isLeapYear(year2, CalType.Gregorian);
    const leap3 = isLeapYear(year3, CalType.Gregorian);
    const leap4 = isLeapYear(year4, CalType.Gregorian);

    try std.testing.expect(leap1 == true);
    try std.testing.expect(leap2 == false);
    try std.testing.expect(leap3 == true);
    try std.testing.expect(leap4 == false);
}

test "dateFromJulianDay" {
    const JD1: f64 = 2436116.31;
    const JD2: f64 = 2451545.0;
    const JD3: f64 = 1842713.0;
    const date1 = try dateFromJulianDay(JD1);
    const date2 = try dateFromJulianDay(JD2);
    const date3 = try dateFromJulianDay(JD3);
    try std.testing.expectEqual(date1.year, 1957);
    try std.testing.expectEqual(date1.month, 10);
    try std.testing.expectApproxEqAbs(date1.decimalDay, 4.81, 0.000001);
    try std.testing.expectEqual(date2.year, 2000);
    try std.testing.expectEqual(date2.month, 1);
    try std.testing.expectApproxEqAbs(date2.decimalDay, 1.5, 0.000001);
    try std.testing.expectEqual(date3.year, 333);
    try std.testing.expectEqual(date3.month, 1);
    try std.testing.expectApproxEqAbs(date3.decimalDay, 27.5, 0.000001);
}

test "julianDay" {
    const date1 = Date{ .year = 1957, .month = 10, .decimalDay = 4.81, .calType = CalType.Gregorian };
    const date2 = Date{ .year = 333, .month = 1, .decimalDay = 27.5, .calType = CalType.Julian };
    const date3 = Date{ .year = 2000, .month = 1, .decimalDay = 1.5, .calType = CalType.Gregorian };
    const date4 = Date{ .year = -123, .month = 12, .decimalDay = 31.0, .calType = CalType.Julian };
    const date5 = Date{ .year = -4712, .month = 1, .decimalDay = 1.5, .calType = CalType.Julian };
    const JD1 = julianDay(date1);
    const JD2 = julianDay(date2);
    const JD3 = julianDay(date3);
    const JD4 = julianDay(date4);
    const JD5 = julianDay(date5);
    try std.testing.expectApproxEqAbs(JD1, 2436116.31, 0.000001);
    try std.testing.expectApproxEqAbs(JD2, 1842713.0, 0.000001);
    try std.testing.expectApproxEqAbs(JD3, 2451545.0, 0.000001);
    try std.testing.expectApproxEqAbs(JD4, 1676496.5, 0.000001);
    try std.testing.expectApproxEqAbs(JD5, 0.0, 0.000001);
}

test "weekdayFromDate" {
    const date1 = Date{ .year = 2024, .month = 11, .decimalDay = 28, .calType = CalType.Gregorian };

    const week1 = weekdayFromDate(date1);

    try std.testing.expectEqual(week1, Week.Thursday);
}
