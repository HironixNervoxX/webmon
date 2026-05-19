const API = '/api';
const list = document.getElementById('list');
const form = document.getElementById('form');
const input = document.getElementById('title');
const emptyState = document.getElementById('empty-state');

// Charger et afficher les tâches depuis l'API
async function load() {
  // 1. Sécurité absolue : Par défaut, on montre TOUJOURS le message "Aucune tâche" 
  // comme ça, même si l'API plante ou met du temps, l'écran n'est pas vide !
  if (emptyState) emptyState.classList.remove('hidden');
  if (list) list.innerHTML = '';

  try {
    const r = await fetch(`${API}/tasks`);
    
    // Si la réponse n'est pas correcte (ex: 404, 500, 502)
    if (!r.ok) {
      console.warn("Le serveur a répondu avec une erreur, on garde l'état vide.");
      return; 
    }

    const tasks = await r.json();
    
    // 2. Si on récupère bien des tâches et qu'il y en a au moins une
    if (tasks && tasks.length > 0) {
      // On cache le message d'état vide puisqu'on a des éléments à montrer
      if (emptyState) emptyState.classList.add('hidden');
      
      // On génère la liste
      list.innerHTML = tasks.map(t =>
        `<li class="${t.done ? 'done' : ''}">
          <input type="checkbox" ${t.done ? 'checked' : ''} onchange="window.toggleTask(${t.id}, this.checked)">
          <span>${escapeHtml(t.title)}</span>
        </li>`
      ).join('');
    }
  } catch (error) {
    // Si le serveur est éteint ou inaccessible (Erreur de connexion)
    console.error("Impossible de joindre l'API, l'état vide reste affiché :", error);
  }
}

// Nettoyage des chaînes de caractères pour éviter les bugs d'affichage
function escapeHtml(text) {
  if (!text) return '';
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

// Changer le statut d'une tâche
window.toggleTask = async function(id, done) {
  try {
    await fetch(`${API}/tasks/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ done })
    });
    load();
  } catch (error) {
    console.error("Erreur lors de la modification du statut :", error);
  }
};

// Ajouter une tâche via le formulaire
form.addEventListener('submit', async e => {
  e.preventDefault();
  const titleValue = input.value.trim();
  
  if (!titleValue) return;

  try {
    await fetch(`${API}/tasks`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: titleValue })
    });
    
    input.value = '';
    load(); // Recharge la liste
  } catch (error) {
    console.error("Échec de l'envoi de la tâche :", error);
  }
});

// Lancement automatique au chargement
load();