// Simple in-memory OTP state for the current app session.
// Keyed by Firebase UID -> OTP code string.

final Map<String, String> pendingOtps = {};
final Set<String> pendingOtpShown = {};

void setPendingOtp(String uid, String code) {
  pendingOtps[uid] = code;
  pendingOtpShown.remove(uid);
}

void clearPendingOtp(String uid) {
  pendingOtps.remove(uid);
  pendingOtpShown.remove(uid);
}

String? getPendingOtpForUid(String uid) => pendingOtps[uid];

void markPendingOtpShown(String uid) {
  pendingOtpShown.add(uid);
}

bool isPendingOtpShown(String uid) => pendingOtpShown.contains(uid);
