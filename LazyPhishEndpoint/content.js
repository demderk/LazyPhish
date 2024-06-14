chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
    if (message.action === 'accessResponse') {
      if (!message.access) {
        window.location.href = chrome.runtime.getURL("error.html");
      }
    }
  });
  
  (async () => {
    const url = window.location.href;
    chrome.runtime.sendMessage({ action: 'checkAccess', url: url });
  })();
  