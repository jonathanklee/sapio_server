'use strict';

/**
 * sapio-application service.
 */

const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::sapio-application.sapio-application');
