var login_window;
function onSuccess(token) {
    login_window.close();
    window.onSuccessFlutter(token);
}
function onFailure(error) {
    login_window.close();
    console.log(error);
    window.onSuccessFlutter(error);
}
function openOauth(type) {
    switch (type) {
        case 0:
            login_window = window.open('https://shachikuengineer.tk/websocket/oauth/google', "login", "toolbar=no,menubar=no,width=500,height=600");
            break;
        case 1:
            login_window = window.open('https://shachikuengineer.tk/websocket/oauth/facebook', "login", "toolbar=no,menubar=no,width=500,height=600");
            break;
        case 2:
            login_window = window.open('https://shachikuengineer.tk/websocket/oauth/line', "login", "toolbar=no,menubar=no,width=500,height=600");
            break;
    }
}