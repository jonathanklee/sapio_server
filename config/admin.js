module.exports = ({ env }) => ({
  auth: {
    secret: env('ADMIN_JWT_SECRET', '0c2b2573e7875d683162ceed987199e8'),
  },
});
