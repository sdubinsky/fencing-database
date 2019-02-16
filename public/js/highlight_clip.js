function submitResult(result){
    var reelId = document.getElementById("reel-id-div").className;
    var clipId = document.getElementById("clip-id-div").className;
    var body = JSON.stringify({
        "reelId": reelId,
        "clipId": clipId,
        "result": result
    });
    var request = new XMLHttpRequest();
    request.open('POST', '/reels/submit');
    request.setRequestHeader("Content-Type", "application/json");
    request.send(body);
}

function rejectClip(e) {
    if (e.code === "ArrowLeft" || e.code === "KeyN"){
        submitResult("reject");
        location.reload(true);
    }
}

function acceptClip(e) {
    if (e.code === "ArrowRight" || e.code === "KeyY"){
        submitResult("accept");
        location.reload(true);
    }
}

function skipClip(e) {
    if (e.code === "ArrowDown") {
        location.reload(true);
    }
}



document.addEventListener("keydown", rejectClip);
document.addEventListener("keydown", acceptClip);
document.addEventListener("keydown", skipClip);
