function reportError(gfy_id){
    var body = JSON.stringify({
        'gfy_id': gfy_id
    });
    var request = new XMLHttpRequest();
    request.open('POST', '/error_report');
    request.setRequestHeader('Content-Type', 'application/json');
    request.send(body);
    var error_elem = document.getElementById('report-error');
    error_elem.innerHTML = 'Thank you!';
    return false;
}
