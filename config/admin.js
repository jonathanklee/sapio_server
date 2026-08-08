module.exports = ({ env }) => ({
  auth: {
    // No fallback on purpose: this repository is public, so a default value
    // would be a publicly known signing key the day ADMIN_JWT_SECRET goes
    // missing - a mis-mounted env_file is enough.
    secret: env('ADMIN_JWT_SECRET'),
  },
});
