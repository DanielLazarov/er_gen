(function (window) {
  'use strict';

  if (typeof window.jQuery === 'undefined') {
    throw new Error('AjaxRequest\'s JavaScript requires jQuery')
  }

  function AjaxRequest(settings){
    this.settings = jQuery.extend({}, settings);
  }

  AjaxRequest.prototype.sendRequest = function(req_settings) {
    
    req_settings = jQuery.extend({}, this.settings, req_settings);
    
    jQuery.ajax(req_settings);
  };

  AjaxRequest.prototype.prepareURIParams = function(params){
    var arr = new Array();
    for(let key in params){
      arr.push(key + '=' + encodeURIComponent(params[key]));
    }
    return arr.join('&');
  }
     
    window.AjaxRequest = AjaxRequest;
})(window);