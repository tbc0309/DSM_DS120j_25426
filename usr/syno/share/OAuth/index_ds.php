<!doctype html>
<head>
<title>Synology App</title>
</head>
<body>
<p> Connecting... </p>
<script language="JavaScript" type="text/javascript">

    var href = window.location.href;
    var index = href.indexOf('?');
    var querys = href.slice(index+1).split('&');
    var params={};
    var callback = function() {};
    for (var i=0;i<querys.length;i++) {
        var tmp = querys[i].split('=');
        params[tmp[0]] = tmp[1];
    }
    var ua = window.navigator.userAgent.toLowerCase();
    var check = function(r) {
        return r.test(ua);
    }
    var isIE = !check(/opera/) && check(/msie/) || check(/trident\/7/); // IE11 or older IE
    if (isIE) {
        callback = params['callback'] ? window.opener[params['callback']] : callback;
        if (callback) {
            callback(params);
        }
    } else {
        window.opener.postMessage(JSON.stringify(params), window.location.origin);
    }
    window.close();

</script>
</body>
</html>
