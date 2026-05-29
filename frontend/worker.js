async function fetchQuotes() {
    try {
        const response = await fetch('http://localhost:4567/api/quotes');
        const data = await response.json();
        // Envia os dados de volta para a tela principal (Vue)
        postMessage(data);
    } catch (error) {
        console.error("Erro no Worker ao buscar dados:", error);
    }
}

fetchQuotes();

setInterval(fetchQuotes, 5000);