const std = @import("std");
const angle = @import("angle.zig");
const time = @import("time.zig");
pub fn main() !void {
    const date = time.Date{ .year = 2024, .month = 11, .decimalDay = 28.0, .calType = time.CalType.Gregorian };
    const day = time.weekdayFromDate(date);
    // const is_leap_year = time.isLeapYear(2021, time.CalType.Gregorian);
    const jd = time.julianDay(date);
    std.debug.print("Day: {any}\n", .{day});
    // std.debug.print("Is Leap Year: {d}\n", .{is_leap_year});
    std.debug.print("Julian Day: {d}\n", .{jd});
}
