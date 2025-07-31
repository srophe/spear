import {
  getEventKeywords,
  getRelationshipOptions,
  getEthnicityOptions,
  getPlaceOptions,
  getEducationFieldsOfStudy,
  populateDropdown,
  renderKeywordList
} from './menu.js';

import { fetchFactoidsWithFilters, fetchFactoidsByMultiType, buildFilterCountQuery } from './search.js';
import { renderKeywordPrettyList } from './list.js'; 

// Global filter state
const state = {
  selectedEventKeywords: new Set(),
  selectedRelationshipKeywords: new Set(),
  selectedEthnicityKeywords: new Set(),
  selectedGenderKeywords: new Set(),
  selectedUncertaintyKeywords: new Set(),
  selectedPlaceKeywords: new Set(),
  // selectedFieldOfStudyKeywords: new Set(),
  currentTab: 'factoids'
};
export function prettifyUri(uri) {
  if (!uri) return '';
  // Remove angle brackets if present
  uri = uri.replace(/^<|>$/g, '');
  // Try to extract the last part after '/' or '#'
  const parts = uri.split(/[\/#]/);
  return parts[parts.length - 1];
}

// Convert state to URLSearchParams string
function stateToUrlParams(state) {
  const params = new URLSearchParams();

  for (const uri of state.selectedGenderKeywords) {
    params.append('gender', uri);
  }
  if (state.uncertainty) {
    params.set('uncertainty', state.uncertainty);
  }



  for (const uri of state.selectedEventKeywords) {
    params.append('event', uri);
  }
  for (const uri of state.selectedRelationshipKeywords) {
    params.append('relationship', uri);
  }
  for (const uri of state.selectedEthnicityKeywords) {
    params.append('ethnicity', uri);
  }
  for (const uri of state.selectedPlaceKeywords) {
    params.append('place', uri);
  }

  return params.toString();
}

// Parse URL params and update state
function updateStateFromUrlParams() {
  const params = new URLSearchParams(window.location.search);

  state.selectedGenderKeywords = new Set(params.getAll('gender'));
  state.uncertainty = params.get('uncertainty') || '';


  state.selectedEventKeywords = new Set(params.getAll('event'));
  state.selectedRelationshipKeywords = new Set(params.getAll('relationship'));
  state.selectedEthnicityKeywords = new Set(params.getAll('ethnicity'));
  state.selectedPlaceKeywords = new Set(params.getAll('place'));
  // state.selectedFieldOfStudyKeywords = new Set(params.getAll('field'));
}


// Utility to toggle keyword filters
function toggleSet(set, value) {
  set.has(value) ? set.delete(value) : set.add(value);
}

// Rendering logic for factoids
function renderFactoidsOG(facts) {
  const container = document.getElementById('factoidResults');
  if (!facts.length) {
    container.innerHTML = '<p>No factoids found.</p>';
    return;
  }
  container.innerHTML = `
    <h4>Factoids</h4>
    <h5>${facts.length} found</h5>
    <ul style="list-style-type: none; padding: 0; margin: 0;">
      ${facts.map(f => `
        <li style=" margin: 2rem;">
          ${f.description ? `<p>${f.description}</p>` : ''}
          ${f.label ? `<br/><em>${f.label}</em>` : ''}
          <a href="${f.uri}" target="_blank">${f.uri}</a>
        </li>
      `).join('')}
    </ul>
 
  `;
}
function renderFactoids(facts) {
  const container = document.getElementById('factoidResults');

  // Filter out factoids that have a `person` URI
    const filtered = facts.filter(f => {
    return !f.uri.startsWith('http://syriaca.org/person/');
  });

  if (!filtered.length) {
    container.innerHTML = '<p>No factoids found.</p>';
    return;
  }

  container.innerHTML = `
    <h4>Factoids</h4>
        <h5 style="margin: 2rem;">${facts.length} results</h5>

    <ul style="list-style-type: none; padding: 0; margin: 0;">
      ${filtered.map(f => `
        <li style="margin: 2rem;">
          ${f.description ? `<p>${f.description}</p>` : ''}
          ${f.label ? `<br/><em>${f.label}</em>` : ''}
          <a href="${f.uri}" target="_blank">${f.uri}</a>
        </li>
      `).join('')}
    </ul>
  `;
}

function clearFilters() {
  // Reset all keyword sets
  state.selectedEventKeywords.clear();
  state.selectedRelationshipKeywords.clear();
  state.selectedEthnicityKeywords.clear();
  state.selectedPlaceKeywords.clear();

  // Reset dropdowns
  state.selectedGenderKeywords.clear();
  state.uncertainty = '';

  document.querySelectorAll('input[name="gender"]').forEach(r => r.checked = r.value === '');
document.querySelectorAll('input[name="uncertainty"]').forEach(r => r.checked = r.value === '');


  // Reset the dropdown UI
  // const genderSelect = document.getElementById('genderSelect');
  // if (genderSelect) genderSelect.value = '';

  // const uncertaintySelect = document.getElementById('uncertaintySelect');
  // if (uncertaintySelect) uncertaintySelect.value = '';

  // // Uncheck any selected keyword checkboxes
  // document.querySelectorAll('input[type="checkbox"]').forEach(cb => {
  //   cb.checked = false;
  // });

  // Clear URL
  history.replaceState(null, '', window.location.pathname);

  // Update results
  updateResults();
}

// Master updater
function updateResults() {
  const queryString = stateToUrlParams(state);
  const newUrl = `${window.location.pathname}?${queryString}`;
  history.replaceState(null, '', newUrl); // updates URL without reloading
  fetchFactoidsWithFilters(state).then(renderFactoids);
}


// Load dropdown menus
function setupDropdowns() {

document.querySelectorAll('input[name="gender"]').forEach(input => {
  input.addEventListener('change', () => {
    if (input.value) state.selectedGenderKeywords.add(input.value);
    updateResults();
  });
});

document.querySelectorAll('input[name="uncertainty"]').forEach(input => {
  input.addEventListener('change', () => {
    const selected = Array.from(
      document.querySelectorAll('input[name="uncertainty"]:checked')
    ).map(cb => cb.value);

    state.uncertainty = selected.join(',');
    updateResults();
  });
});


}

function searchMenuItems(inputId, itemsContainerId) {
  const searchInput = document.getElementById(inputId);
  searchInput.addEventListener('input', () => {
    const filter = searchInput.value.toLowerCase();
    const allItems = document.querySelectorAll(`#${itemsContainerId} li`);

    allItems.forEach(li => {
      const text = li.textContent.toLowerCase();
      li.style.display = text.includes(filter) ? 'block' : 'none';
    });
  });
}


// Load keyword menus
function setupKeywordLists() {

    renderKeywordPrettyList(
        getEventKeywords(),
        'eventKeywordItems',
        'keyword',
        'keyword',
        uri => {
            toggleSet(state.selectedEventKeywords, uri);
            updateResults();
        }
    );

    renderKeywordPrettyList(
        getEthnicityOptions(),
        'ethnicityKeywordItems',
        'ethnicity',
        'ethnicity',
        uri => {
            toggleSet(state.selectedEthnicityKeywords, uri);
            updateResults();
        }
    );
    renderKeywordList(
        getPlaceOptions(),
        'placeKeywordItems',
        'placeKeywordList',
        'label', 'place',
        uri => {
            toggleSet(state.selectedPlaceKeywords, uri);
      updateResults();
    }
  );
  renderKeywordList(
    getRelationshipOptions(),
    'relationshipKeywordItems',
    'relationshipKeywordList',
    'label', 'subject',
    uri => {
      toggleSet(state.selectedRelationshipKeywords, uri);
      updateResults();
    }
  );
}

// Initialize everything
export function initializeFilter() {
  updateStateFromUrlParams(); // Load state from URL
  document.getElementById('clearFiltersBtn').addEventListener('click', clearFilters);
  setupDropdowns();
  setupKeywordLists();
  updateResults(); // Initial load (optional)
  searchMenuItems('event-search', 'eventKeywordItems');
  searchMenuItems('relationship-search', 'relationshipKeywordItems');
  searchMenuItems('place-search', 'placeKeywordItems');


}
