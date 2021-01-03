function submitResult(result) {
    var clipId = document.getElementById("clip-id-div").className;
    var body = JSON.stringify({
        "clipId": clipId,
        "result": result
    });
    var request = new XMLHttpRequest();
    //This is a sync request because otherwise the page reloads too quickly
    request.open('POST', '/fencing-ai/submit', false);
    request.setRequestHeader("Content-Type", "application/json");
    request.send(body);
}

function setKeycodes(codes) {
    function listener(e) {
        result = codes[e];
        if (result) {
            submitResult(codes[e]);
            location.reload(true);
        }
    }

    document.addEventListener('keydown', listener);
}
