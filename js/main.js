(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
})(window,document,'script','//www.google-analytics.com/analytics.js','ga');

var xmlhttp = new XMLHttpRequest();
var url = "https://api.github.com/repos/nondev/spoon/commits";

xmlhttp.onreadystatechange = function() {
  if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
    var latest = JSON.parse(xmlhttp.responseText)[0];
    var date = $.timeago(latest.commit.author.date);
    var url = latest.html_url;
    console.log(date);
    $("#updated").text("updated " + date);
    $("#updated").attr("href", url);
  }
}

$(function() {
  $('[data-toggle="tooltip"]').tooltip();
  xmlhttp.open("GET", url, true);
  xmlhttp.send();

  ((window.gitter = {}).chat = {}).options = {
    room: 'nondev/spoon',
    activationElement: false
  };
  ga('create', 'UA-68102301-1', 'auto');
  ga('send', 'pageview');
});
