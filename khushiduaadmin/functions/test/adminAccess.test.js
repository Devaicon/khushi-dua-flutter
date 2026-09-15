"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  normalizeEmail,
  validateInvite,
  claimableEmail,
  revokeProblem,
} = require("../adminAccess");

test("normalizeEmail trims and lowercases", () => {
  assert.equal(normalizeEmail("  Ops@Company.COM "), "ops@company.com");
  assert.equal(normalizeEmail(undefined), "");
  assert.equal(normalizeEmail(42), "");
});

test("validateInvite accepts a normal invite and defaults the role", () => {
  const result = validateInvite({
    email: "Ops@Company.com",
    firstName: " Sara ",
    lastName: "Khan",
  });
  assert.deepEqual(result, {
    value: {
      email: "ops@company.com",
      role: "Admin",
      firstName: "Sara",
      lastName: "Khan",
    },
  });
});

test("validateInvite accepts Super_Admin", () => {
  assert.equal(
      validateInvite({email: "a@b.co", role: "Super_Admin"}).value.role,
      "Super_Admin",
  );
});

test("validateInvite rejects a missing or malformed email", () => {
  assert.match(validateInvite({email: "not-an-email"}).error, /valid email/);
  assert.match(validateInvite({}).error, /valid email/);
  assert.match(validateInvite(undefined).error, /valid email/);
});

test("validateInvite rejects an unknown role", () => {
  assert.match(
      validateInvite({email: "a@b.co", role: "Owner"}).error,
      /Role must be/,
  );
});

test("validateInvite rejects overlong names", () => {
  assert.match(
      validateInvite({email: "a@b.co", firstName: "x".repeat(101)}).error,
      /100 characters/,
  );
});

test("claimableEmail requires a Google sign-in with a verified email", () => {
  const google = {
    email: "Ops@Company.com",
    email_verified: true,
    firebase: {sign_in_provider: "google.com"},
  };
  assert.equal(claimableEmail(google), "ops@company.com");
  assert.equal(claimableEmail({...google, email_verified: false}), null);
  // An app user who signs up with email/password using an invited address
  // must not be able to claim the invite.
  assert.equal(
      claimableEmail({...google, firebase: {sign_in_provider: "password"}}),
      null,
  );
  assert.equal(claimableEmail(undefined), null);
});

test("revokeProblem allows removing another admin", () => {
  assert.equal(
      revokeProblem({
        callerUid: "a",
        targetUid: "b",
        targetRole: "Admin",
        superAdminCount: 1,
      }),
      null,
  );
});

test("revokeProblem blocks removing yourself", () => {
  assert.match(
      revokeProblem({
        callerUid: "a",
        targetUid: "a",
        targetRole: "Super_Admin",
        superAdminCount: 3,
      }),
      /your own/,
  );
});

test("revokeProblem blocks removing the last super admin", () => {
  assert.match(
      revokeProblem({
        callerUid: "a",
        targetUid: "b",
        targetRole: "Super_Admin",
        superAdminCount: 1,
      }),
      /last super admin/,
  );
  assert.equal(
      revokeProblem({
        callerUid: "a",
        targetUid: "b",
        targetRole: "Super_Admin",
        superAdminCount: 2,
      }),
      null,
  );
});

test("revokeProblem requires a target", () => {
  assert.match(
      revokeProblem({callerUid: "a", targetUid: "", superAdminCount: 2}),
      /Choose an admin/,
  );
});
