import {
  getEventKeywords,
  getRelationshipOptions,
  getEthnicityOptions,
  getPlaceOptions,
  getEducationFieldsOfStudy,
  populateDropdown,
  getOccupationOptions,
  renderKeywordList
} from './menu.js';

import { fetchFactoidsWithFilters, fetchFactoidsByMultiType, fetchEventFactoids } from './search.js';
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
  // currentTab: 'factoids'
  selectedOccupationKeywords: new Set(),
  selectedSourceKeywords: new Set()
};
export function prettifyUri(uri) {
  if (!uri) return '';
  // Remove angle brackets if present
  uri = uri.replace(/^<|>$/g, '');
  // Try to extract the last part after '/' or '#'
  const parts = uri.split(/[\/#]/);
  return parts[parts.length - 1];
}
const sourceLabels = {
  "https://spear-prosop.org/letters-severus": "Letters of Severus of Antioch",
  "https://spear-prosop.org/lives-eastern-saints": "Lives of the Eastern Saints",
  "https://spear-prosop.org/chronicle-edessa": "Chronicle of Edessa"

};

function getSourceLabel(uri) {
  return sourceLabels[uri] || prettifyUri(uri);
}

export const FILTER_MAP = {
  name:         { stateKey: 'name', urlKey: 'nameSearch' },
  gender:       { stateKey: 'selectedGenderKeywords', urlKey: 'gender' },
  source:       { stateKey: 'selectedSourceKeywords', urlKey: 'source' },
  occupation:   { stateKey: 'selectedOccupationKeywords', urlKey: 'occupation' },
  event:        { stateKey: 'selectedEventKeywords', urlKey: 'event' },
  relationship: { stateKey: 'selectedRelationshipKeywords', urlKey: 'relationship' },
  place:        { stateKey: 'selectedPlaceKeywords', urlKey: 'place' }
};


// Convert state to URLSearchParams string
export function stateToUrlParams(state) {
  const params = new URLSearchParams();

  for (const uri of state.selectedGenderKeywords) {
    params.append('gender', uri);
  }
  if (state.uncertainty) {
    params.set('uncertainty', state.uncertainty);
  }
  for (const uri of state.selectedSourceKeywords) {
    params.append('source', uri);

  }
   for (const uri of state.selectedOccupationKeywords) {
    params.append('occupation', uri);

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
export function updateStateFromUrlParams() {
  const params = new URLSearchParams(window.location.search);

  state.selectedGenderKeywords = new Set(params.getAll('gender'));
  state.uncertainty = params.get('uncertainty') || '';


  state.selectedEventKeywords = new Set(params.getAll('event'));
  state.selectedRelationshipKeywords = new Set(params.getAll('relationship'));
  state.selectedEthnicityKeywords = new Set(params.getAll('ethnicity'));
  state.selectedPlaceKeywords = new Set(params.getAll('place'));
  state.selectedSourceKeywords = new Set(params.getAll('source'));
  // state.selectedFieldOfStudyKeywords = new Set(params.getAll('field'));
  state.selectedOccupationKeywords = new Set(params.getAll('occupation'));
}


// Utility to toggle keyword filters
function toggleSet(set, value) {
  set.has(value) ? set.delete(value) : set.add(value);
}

// Rendering logic for factoids
function renderFactoids(facts) {
  document.getElementById('defaultFactoidResults').classList.add('d-none');
  document.getElementById('factoidResults').classList.remove('d-none');
  console.log("Rendering factoids:", facts);
  const container = document.getElementById('factoidResults');
  // Filter out factoids that have a `person` URI, why do they exist in database?
  // This is a temporary fix, we should not have these factoids in the database.
  //   const filtered = facts.filter(f => {
  //   return !f.uri.startsWith('http://syriaca.org/person/');
  // });

  if (!facts) {
    container.innerHTML = '<p>No factoids found.</p>';
    return;
  }

  container.innerHTML = `
  <h4>Factoids</h4>
  <h5 style="margin: 2rem; border-bottom: 1px solid #ccc;">${facts.length} results</h5>

  <ul style="list-style-type: none; padding: 0; margin: 2rem;">
    ${facts.map(f => `
      <li style="padding: 1rem 0; border-bottom: 1px solid #ccc;">
        ${f.description ? `<em> ${f.description} </em>` : ''}${f.source ? ` [${getSourceLabel(f.source)}]<br/>` : ''}
        <a href="${f.uri}" target="_blank">${f.uri}</a>
        ${f.label ? `<br/>Related person: <em>${f.label}</em>` : ''}
        ${f.person ? `<br/>Related person link:<br/><a href="${f.person}" target="_blank">${f.person}</a>` : ''}
      </li>
    `).join('')}
  </ul>
`;

}

function clearNameResults() {
  const browseItemsContainer = document.getElementById('browse--items-container');
    if (browseItemsContainer) browseItemsContainer.innerHTML = '';
  const browseContainer = document.getElementById('browse--items');
    if (browseContainer) browseContainer.innerHTML = '';  
}
function clearPersonResults() {
  const browseItemsContainer = document.getElementById('browse--items-container');
  if (browseItemsContainer) browseItemsContainer.innerHTML = '';
  const browseContainer = document.getElementById('browse--items');
    if (browseContainer) browseContainer.innerHTML = '';  
}


function clearFilters() {
  // Reset all keyword sets
  state.selectedEventKeywords.clear();
  state.selectedRelationshipKeywords.clear();
  state.selectedEthnicityKeywords.clear();
  state.selectedPlaceKeywords.clear();
  state.selectedOccupationKeywords.clear();
  state.persons.clear();
  // Reset dropdowns
  state.selectedGenderKeywords.clear();
  state.uncertainty = '';
  document.querySelectorAll('input[name="gender"]').forEach(cb => { cb.checked = false; });
  document.querySelectorAll('input[name="uncertainty"]').forEach(r => r.checked = r.value === '');
  document.querySelectorAll('input[name="source"]').forEach(cb => { cb.checked = false; });

  state.selectedSourceKeywords.clear();
  state.selectedUncertaintyKeywords.clear();

  // Clear URL
  history.replaceState(null, '', window.location.pathname);
  
  const browseItemsContainer = document.getElementById('browse--items-container');
    if (browseItemsContainer) browseItemsContainer.innerHTML = '';
  const browseContainer = document.getElementById('browse--items');
    if (browseContainer) browseContainer.innerHTML = '';  

  // Update results
  updateResults();
}

// Master updater
export function updateResults() {
  console.log("Updating results with state:", state);
  const queryString = stateToUrlParams(state);
  console.log("Generated query string:", queryString);
  const newUrl = `${window.location.pathname}?${queryString}`;
  clearNameResults();
  clearPersonResults();
  history.replaceState(null, '', newUrl); // updates URL without reloading
  fetchEventFactoids(state).then(renderFactoids);
}


// Load dropdown menus
function setupDropdowns() {

  document.querySelectorAll('input[name="gender"]').forEach(input => {
    input.addEventListener('change', () => {
      if (!input.value) return; // no empty values in your markup
      if (input.checked) state.selectedGenderKeywords.add(input.value);
      else state.selectedGenderKeywords.delete(input.value);
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
  const sourceCheckboxes = Array.from(document.querySelectorAll('input[name="source"]'));
  const allSourcesCb = sourceCheckboxes[0];
  const specificCbs = sourceCheckboxes.slice(1);
  const ALL_URIS = specificCbs.map(cb => cb.value);

  // Initialize state from DOM (so default-checked boxes populate state)
  state.selectedSourceKeywords = new Set(
    specificCbs.filter(cb => cb.checked).map(cb => cb.value)
  );

  sourceCheckboxes.forEach((cb, idx) => {
    cb.addEventListener('change', () => {
      if (idx === 0) {
        // "All sources" toggled
        if (cb.checked) {
          specificCbs.forEach(s => (s.checked = true));
          state.selectedSourceKeywords = new Set(ALL_URIS);  // restrict to all three
        } else {
          // Unchecking "All" doesn't change specifics; recompute from DOM
          state.selectedSourceKeywords = new Set(
            specificCbs.filter(s => s.checked).map(s => s.value)
          );
        }
      } else {
        // A specific box toggled
        if (cb.checked) state.selectedSourceKeywords.add(cb.value);
        else state.selectedSourceKeywords.delete(cb.value);

        // Keep "All" in sync
        allSourcesCb.checked = ALL_URIS.every(u => state.selectedSourceKeywords.has(u));
      }
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
    renderKeywordList(
    getOccupationOptions(),
    'occupationKeywordItems',
    'occupationKeywordList',
    'label', 'occupation',
    uri => {
      toggleSet(state.selectedOccupationKeywords, uri);
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
  searchMenuItems('event-search', 'eventKeywordItems');
  searchMenuItems('relationship-search', 'relationshipKeywordItems');
  searchMenuItems('place-search', 'placeKeywordItems');
  searchMenuItems('occupation-search', 'occupationKeywordItems');

  updateResults();
}
  import allEventsFactoidsData from "./types/factoid/defaultFactoids.json" with { type: 'json' };

    const typeMap = {
      "event-participant": "Event Participant",
      "ethnicity": "Ethnicity",
      "place": "Place",
      "spouse-of": "Spouse of",
      "field-of-study": "Field of Study",
      "occupation": "Occupation",
      "gender": "Gender",
      "name-variant": "Name Variant",
      "sibling-of": "Sibling of",
      "professional-relationship": "Professional Relationship",
      "socec-status": "Socio-Economic Status",
      "religious-affiliation": "Religious Affiliation",
      "birth-place": "Birth Place",
      "death-place": "Death Place",
      "residence": "Residence",
      "citizenship": "Citizenship",
      "education": "Education"
    };


async function renderDefaultEventFactoids() {
  const queryResults = document.getElementById('factoidResults');
  queryResults.classList.add('d-none');
  const factoidDisplay = document.getElementById('defaultFactoidResults');
  factoidDisplay.classList.remove('d-none');

  const factoids = allFactoidsData.results.bindings.map(f => ({
    uri: f.factoid.value,
    label: f.label.value,
    description: f.description?.value || '',
    type: f.type.value,
    person: f.person?.value || ''
  }));
  try {
   
    if (!Array.isArray(factoids) || factoids.length === 0) {
      factoidDisplay.innerHTML = "<em>No factoids found in the database.</em>";
      return;
    }

    factoidDisplay.innerHTML = `

<ul style="list-style-type: none; padding-left: 2rem; padding-right: 2rem; ">
 <h4>All Person Factoids</h4>
        <h5 style="margin: 2rem;">${factoids.length} results</h5>

  ${factoids.map(f => {
    const typeSlug = f.type?.split('/').pop();
    const typeLabel = typeMap[typeSlug] || typeSlug;
    const personLink = f.person ? `<a href="${f.person}" target="_blank">${f.label}</a>` : f.label;

    return `
      <li style="padding-top: 1rem; padding-bottom: 1rem;">
        ${f.description ? `<em>${f.description}</em><br/>` : ''}
        <a href="${f.uri}" target="_blank">${f.uri}</a><br/>
        ${typeLabel} (${personLink})
      </li>
    `;
  }).join('')}
</ul>
    `;
  } catch (err) {
    console.error("Failed to load factoids:", err);
    factoidDisplay.innerHTML = "<em>Failed to load factoids.</em>";
  }
}
// ✅ Clear one section’s filters from state and URL
export function clearSection(section, state) {
  const map = FILTER_MAP[section];
  if (!map) return;

  // Clear from state
  if (state.filters && state.filters[map.stateKey]) {
    delete state.filters[map.stateKey];
  }

  // Clear from URL
  const url = new URL(window.location.href);
  url.searchParams.delete(map.urlKey);
  history.replaceState({}, '', url.toString());
}
export function clearAllFilters(state) {
  // Clear from state
  Object.values(FILTER_MAP).forEach(({ stateKey }) => {
    if (state.filters[stateKey]) delete state.filters[stateKey];
  });

  // Clear from URL (preserve type)
  const url = new URL(window.location.href);
  const type = url.searchParams.get('type');
  url.search = type ? `type=${type}` : '';
  history.replaceState({}, '', url.toString());
}
export function clearPersonSection(section, state) {
  const p = state.filters.person;
  if (!p) return;

  // map section name → property key inside state.filters.person
  const map = {
    names:        'name',
    gender:       'selectedGenderKeywords',
    source:       'selectedSourceKeywords',
    occupations:  'selectedOccupationKeywords',
    events:       'selectedEventKeywords',
    relationships:'selectedRelationshipKeywords',
    place:        'selectedPlaceKeywords'
  };

  const key = map[section];
  if (!key) return;

  const val = p[key];
  if (val instanceof Set) val.clear();
  else if (Array.isArray(val)) val.length = 0;
  else if (typeof val === 'string') p[key] = '';

  // also scrub that parameter from the URL
  const url = new URL(window.location.href);
  url.searchParams.delete(section === 'names' ? 'nameSearch' : section.replace(/s$/, ''));
  history.replaceState({}, '', url);
}
