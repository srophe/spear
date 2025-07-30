import {
  getEventKeywords,
  getRelationshipOptions,
  getEthnicityOptions,
  getPlaceOptions,
  getEducationFieldsOfStudy,
  populateDropdown,
  renderKeywordList
} from './menu.js';

import { fetchFactoidsWithFilters } from './search.js';
import { renderKeywordPrettyList } from './list.js'; 

// Global filter state
const state = {
  selectedEventKeywords: new Set(),
  selectedRelationshipKeywords: new Set(),
  selectedEthnicityKeywords: new Set(),
  gender: '',
  uncertainty: '',
  place: '',
  fieldOfStudy: '',
  currentTab: 'factoids'
};

// Utility to toggle keyword filters
function toggleSet(set, value) {
  set.has(value) ? set.delete(value) : set.add(value);
}

// Rendering logic for factoids
function renderFactoids(facts) {
  const container = document.getElementById('factoidResults');
  if (!facts.length) {
    container.innerHTML = '<p>No factoids found.</p>';
    return;
  }
  container.innerHTML = `
    <h3>Related Factoids</h3>
    <ul>
      ${facts.map(f => `
        <li>
          <a href="${f.uri}" target="_blank">${f.uri}</a>
          ${f.description ? `<br/><small>${f.description}</small>` : ''}
          ${f.label ? `<br/><em>${f.label}</em>` : ''}
        </li>
      `).join('')}
    </ul>
  `;
}

// Master updater
function updateResults() {
  fetchFactoidsWithFilters(state).then(renderFactoids);
}

// Load dropdown menus
function setupDropdowns() {
//   populateDropdown(getEthnicityOptions(), 'ethnicitySelect', 'ethnicity', 'ethnicity');
  populateDropdown(getPlaceOptions(), 'placeSelect', 'label', 'place');
  populateDropdown(getEducationFieldsOfStudy(), 'fieldOfStudySelect', 'label', 'subject');

//   document.getElementById('ethnicitySelect').addEventListener('change', e => {
//     state.ethnicity = e.target.value;
//     updateResults();
//   });

  document.getElementById('placeSelect').addEventListener('change', e => {
    state.place = e.target.value;
    updateResults();
  });

  document.getElementById('fieldOfStudySelect').addEventListener('change', e => {
    state.fieldOfStudy = e.target.value;
    updateResults();
  });

  document.getElementById('genderSelect').addEventListener('change', e => {
    state.gender = e.target.value;
    updateResults();
  });

  document.getElementById('uncertaintySelect').addEventListener('change', e => {
    state.uncertainty = e.target.value;
    updateResults();
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
  setupDropdowns();
  setupKeywordLists();
  updateResults(); // Initial load (optional)
}
