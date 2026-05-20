const API = '/api';
const list = document.getElementById('list');
const form = document.getElementById('form');
const input = document.getElementById('title');
const emptyState = document.getElementById('empty-state');

// Charger et afficher les tâches depuis le vrai Backend
async function load() {
  try {
    const r = await fetch(`${API}/tasks`);
    
    if (!r.ok) {
      throw new Error("Réponse serveur invalide");
    }

    const tasks = await r.json();
    
    // Si on a reçu des tâches
    if (tasks && tasks.length > 0) {
      if (emptyState) emptyState.classList.add('hidden');
      
      list.innerHTML = tasks.map(t =>
        `<li class="${t.done ? 'done' : ''}">
          <label class="task-content">
            <input type="checkbox" ${t.done ? 'checked' : ''} onchange="window.toggleTask(${t.id}, this.checked)">
            <span>${escapeHtml(t.title)}</span>
          </label>
          <button class="btn-delete" onclick="window.deleteTask(${t.id})" aria-label="Supprimer">×</button>
        </li>`
      ).join('');
    } 
    // Si le serveur répond mais la liste est vide (0 tâche)
    else {
      list.innerHTML = '';
      if (emptyState) {
        emptyState.classList.remove('hidden');
        emptyState.innerHTML = `<p>Aucune tâche en cours. L'infrastructure est stable ! ✨</p>`;
      }
    }
  } catch (error) {
    console.error("Erreur d'infrastructure lors du chargement :", error);
    // Affichage de l'alerte rouge si le backend est injoignable
    if (emptyState) {
      emptyState.classList.remove('hidden');
      emptyState.innerHTML = `<p style="color: #ef4444;">⚠️ Impossible de charger les tâches. L'infrastructure est injoignable !</p>`;
    }
  }
}

// Protection contre l'injection de code dans l'interface
function escapeHtml(text) {
  if (!text) return '';
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

// Cocher / Décocher une tâche via l'API (PATCH)
window.toggleTask = async function(id, done) {
  try {
    const response = await fetch(`${API}/tasks/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ done })
    });
    if (!response.ok) throw new Error("Erreur de mise à jour");
    load();
  } catch (error) {
    console.error("Erreur lors de la modification du statut :", error);
  }
};

// Supprimer définitivement une tâche via l'API (DELETE)
window.deleteTask = async function(id) {
  try {
    const response = await fetch(`${API}/tasks/${id}`, {
      method: 'DELETE'
    });
    if (!response.ok) throw new Error("Erreur de suppression");
    load(); // Recharge la liste après suppression
  } catch (error) {
    console.error("Erreur lors de la suppression de la tâche :", error);
  }
};

// Soumettre le formulaire pour ajouter une tâche (POST)
form.addEventListener('submit', async e => {
  e.preventDefault();
  const titleValue = input.value.trim();
  
  if (!titleValue) return;

  try {
    const response = await fetch(`${API}/tasks`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: titleValue })
    });
    
    if (!response.ok) {
      throw new Error("Erreur serveur à l'envoi");
    }

    input.value = '';
    load(); // Recharge la liste proprement
    
  } catch (error) {
    console.error("Échec de la synchronisation :", error);
    if (emptyState) {
      emptyState.classList.remove('hidden');
      emptyState.innerHTML = `<p style="color: #ef4444;">⚠️ Échec de l'envoi. L'infrastructure est injoignable !</p>`;
    }
  }
});

// Lancement automatique au chargement de la page
load();