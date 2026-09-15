"use strict";

/**
 * Pure rules for who may become or stop being an admin. No Firebase imports,
 * so every rule here is covered by `npm test` without an emulator.
 */

const ROLES = Object.freeze(["Admin", "Super_Admin"]);
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const MAX_NAME = 100;

/** Trim and lowercase an email; anything that isn't a string becomes "". */
function normalizeEmail(value) {
  return typeof value === "string" ? value.trim().toLowerCase() : "";
}

function cleanName(value) {
  return typeof value === "string" ? value.trim() : "";
}

/** Returns {value: {...}} for a valid invite, otherwise {error: message}. */
function validateInvite(data) {
  const input = data || {};
  const email = normalizeEmail(input.email);
  if (!EMAIL_PATTERN.test(email) || email.length > 254) {
    return {error: "A valid email address is required."};
  }

  const role = input.role === undefined ? "Admin" : input.role;
  if (!ROLES.includes(role)) {
    return {error: `Role must be one of: ${ROLES.join(", ")}.`};
  }

  const firstName = cleanName(input.firstName);
  const lastName = cleanName(input.lastName);
  if (firstName.length > MAX_NAME || lastName.length > MAX_NAME) {
    return {error: `Names must be ${MAX_NAME} characters or fewer.`};
  }

  return {value: {email, role, firstName, lastName}};
}

/**
 * The email an ID token may claim an invite for, or null.
 *
 * Only Google sign-ins count, and only when Google verified the address:
 * the mobile app lets anyone create an email/password account with any
 * address, verified or not, and that must never unlock admin access.
 */
function claimableEmail(token) {
  if (!token) return null;
  const provider = token.firebase && token.firebase.sign_in_provider;
  if (provider !== "google.com") return null;
  if (token.email_verified !== true) return null;
  return normalizeEmail(token.email) || null;
}

/** Returns why a revoke must be refused, or null when it is allowed. */
function revokeProblem({callerUid, targetUid, targetRole, superAdminCount}) {
  if (!targetUid) return "Choose an admin to remove.";
  if (callerUid === targetUid) return "You can't remove your own access.";
  if (targetRole === "Super_Admin" && superAdminCount <= 1) {
    return "You can't remove the last super admin.";
  }
  return null;
}

module.exports = {
  ROLES,
  normalizeEmail,
  validateInvite,
  claimableEmail,
  revokeProblem,
};
