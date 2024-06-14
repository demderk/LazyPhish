chrome.runtime.onMessage.addListener(async (message, sender, sendResponse) => {
    if (message.action === 'checkAccess') {
      const url = message.url;
      const apiUrl = "http://127.0.0.1:8080/phishing"; // Измененный серверный URL
  
      try {
        const response = await fetch(apiUrl, {
          method: "POST",
          headers: {
            "Content-Type": "application/json"
          },
          body: JSON.stringify({ host: url }) // Измененный формат данных
        });
  
        const data = await response.json();
        chrome.tabs.sendMessage(sender.tab.id, { action: 'accessResponse', access: !data.isPhishing });
      } catch (error) {
        console.error("Ошибка при проверке доступа:", error);
        chrome.tabs.sendMessage(sender.tab.id, { action: 'accessResponse', access: false });
      }
    }
  });
  