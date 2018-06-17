/*jshint esversion: 6 */

exports.handler = (event, context, callback) => {
    setTimeout(() => {callback(null, "{id: 1}");}, 100);
};