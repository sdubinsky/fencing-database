function rejectClip(e) {
    if (e.code === "ArrowLeft" || "KeyJ"){
        button = document.getElementById("submitButton");
        button.click();
    }
}

function acceptClip(e) {
    if (e.code === "ArrowRight"){
        button = document.getElementById("submitButton");
        button.click();
    }
}

function skipClip(e) {
    if (e.code === "ArrowDown") {
        button = document.getElementById("submitButton");
        button.click();
    }
}

document.addEventListener("keydown", rejectClip);
document.addEventlistener("keydown", acceptClip);
document.addEventListener("keydown", skipClip);
