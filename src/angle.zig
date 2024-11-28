const std = @import("std");
const math = std.math;

inline fn degFromDMS(deg: i64, min: i64, sec: f64) f64 {
    const m, const s = if (deg < 0) .{ -@as(i64, @intCast(@abs(min))), -@abs(sec) } else .{ @as(i64, @intCast(@abs(min))), @abs(sec) };
    return @as(f64, @floatFromInt(deg)) + @as(f64, @floatFromInt(m)) / 60.0 + s / 3600.0;
}

inline fn dmsFromDeg(deg: f64) struct { d: i64, m: i64, s: f64 } {
    const d: i64 = @intFromFloat(deg);
    const m: i64 = @intFromFloat((deg - @as(f64, @floatFromInt(d))) * 60.0);
    const s = (deg - @as(f64, @floatFromInt(d)) - @as(f64, @floatFromInt(m)) / 60.0) * 3600.0;
    return .{ .d = d, .m = m, .s = s };
}
inline fn degFromHMS(h: i64, m: i64, s: f64) f64 {
    return 15.0 * (@as(f64, @floatFromInt(h)) + @as(f64, @floatFromInt(m)) / 60.0 + s / 3600.0);
}

inline fn hmsFromDeg(deg: f64) struct { h: i64, m: i64, s: f64 } {
    const h: i64 = @intFromFloat(deg / 15.0);
    const m: i64 = @intFromFloat((deg / 15.0 - @as(f64, @floatFromInt(h))) * 60.0);
    const s: f64 = (deg / 15.0 - @as(f64, @floatFromInt(h)) - @as(f64, @floatFromInt(m)) / 60.0) * 3600.0;
    return .{ .h = h, .m = m, .s = s };
}

inline fn limitTo360(deg: f64) f64 {
    const n: i64 = @intFromFloat(deg / 360.0);
    var limited: f64 = deg - @as(f64, @floatFromInt(n)) * 360.0;
    if (limited < 0.0) {
        limited += 360.0;
    }
    return limited;
}

inline fn limitTo2PI(angle: f64) f64 {
    const n: i64 = @intFromFloat(angle / (2.0 * math.pi));
    var limited: f64 = angle - @as(f64, @floatFromInt(n)) * 2.0 * math.pi;
    if (limited < 0.0) {
        limited += 2.0 * math.pi;
    }
    return limited;
}

test "dms" {
    const deg = 45.0;
    const dms = dmsFromDeg(deg);
    const deg2 = degFromDMS(dms.d, dms.m, dms.s);
    try std.testing.expect(@abs(deg - deg2) < 0.0001);
}

test "hms" {
    const deg = 45.0;
    const hms = hmsFromDeg(deg);
    const deg2 = degFromHMS(hms.h, hms.m, hms.s);
    try std.testing.expect(@abs(deg - deg2) < 0.0001);
}

test "limit" {
    const deg = 12312312.1122;
    const deg2 = limitTo360(deg);
    const deg3 = math.degreesToRadians(deg);
    const deg4 = limitTo2PI(deg3);
    try std.testing.expect(deg2 - 312.1122 < 0.0001);
    try std.testing.expect(deg4 - math.degreesToRadians(312.1122) < 0.0001);
}
