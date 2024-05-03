function refreshOnUpdate() {
  const watchout = new WebSocket(`ws://${location.host}/refreshOnUpdate`);
  watchout.addEventListener("message", (e) => {
    if (e.data == "1") {
      console.log("REFRESHING PAGE...");
      location.reload();
    } else {
      console.log("RECEIVED: ", e.data);
    }
  });
  watchout.addEventListener("close", () => {
    setTimeout(() => {
      console.log("The Refresh WebSocket is closed. Trying again...");
      refreshOnUpdate();
    }, 1000);
  });
}
refreshOnUpdate();
