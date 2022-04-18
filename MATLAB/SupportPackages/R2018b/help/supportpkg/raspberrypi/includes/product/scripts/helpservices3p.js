function handleDocLinksClick3P(aTags) {
  var i;
  for (i = 0; i < aTags.length; i++) {
    aTags[i].onclick = function(evt) {
         if (evt.target) {
             var href = evt.target;
             var hrefString = String(href);
             if (hrefString) {
                 var currentPageHost = window.location.host;
                 var currentPageProtocol = window.location.protocol;
                 var currentPage = window.location.href;
                 if (hrefString && hrefString.match(/^\s*matlab:.*/)) {
                     evt.stopImmediatePropagation();
                     var messageObj = {
                         "url" : hrefString,
                         "currenturl" : currentPage
                     };
                     var services = {
                        "messagechannel" : "matlab"
                     }
                     requestHelpService(messageObj, services, function() {});
                     return false;
                 } else if (hrefString
                     && (hrefString.indexOf(currentPageProtocol) < 0 || hrefString.indexOf(currentPageHost) < 0)
                     && hrefString.indexOf('http') === 0) {
                     evt.stopImmediatePropagation();
                     var messageObj = {
                         "url" : hrefString
                     };
                     var services = {
                        "messagechannel" : "externalclick"
                     }
                     requestHelpService(messageObj, services , function() {});
                     return false;
                 }
             }
         }
    }                        
  }
}