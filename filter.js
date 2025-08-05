import {
  getEventKeywords,
  getRelationshipOptions,
  getEthnicityOptions,
  getPlaceOptions,
  getEducationFieldsOfStudy,
  populateDropdown,
  renderKeywordList
} from './menu.js';

import { fetchFactoidsWithFilters, fetchFactoidsByMultiType } from './search.js';
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
  // currentTab: 'factoids',
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

// Convert state to URLSearchParams string
function stateToUrlParams(state) {
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
  state.selectedSourceKeywords = new Set(params.getAll('source'));
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
function renderFactoids(facts) {
  document.getElementById('defaultFactoidResults').classList.add('d-none');
  document.getElementById('factoidResults').classList.remove('d-none');
  console.log("Rendering factoids:", facts);
  const container = document.getElementById('factoidResults');

  // Filter out factoids that have a `person` URI, why??
    const filtered = facts.filter(f => {
    return !f.uri.startsWith('http://syriaca.org/person/');
  });

  if (!filtered.length) {
    container.innerHTML = '<p>No factoids found.</p>';
    return;
  }
  console.log("Filtered factoids:", filtered);
  // container.innerHTML = `
  //   <h4>Factoids</h4>
  //       <h5 style="margin: 2rem;">${facts.length} results</h5>

  //   <ul style="list-style-type: none; padding: 0; margin: 0;">
  //     ${filtered.map(f => `
  //       <li style="margin: 2rem;">
  //         ${f.description ? `<p><em>Content:</em><br/> ${f.description}</p>` : ''}

  //         <em>Factoid link:</em><br/>
  //         <a href="${f.uri}" target="_blank">${f.uri}</a>
  //                   ${f.label ? `<br/><em>${f.label}</em>` : ''}
  //         ${f.person ? `<br/><em>Related person link:</em><br/><a href="${f.person}" target="_blank">${f.person}</a>` : ''}
  //       </li>
  //     `).join('')}
  //   </ul>
  // `;
  container.innerHTML = `
  <h4>Factoids</h4>
  <h5 style="margin: 2rem; border-bottom: 1px solid #ccc;">${filtered.length} results</h5>

  <ul style="list-style-type: none; padding: 0; margin: 2rem;">
    ${filtered.map(f => `
      <li style="padding: 1rem 0; border-bottom: 1px solid #ccc;">
        ${f.description ? `Description:<br/><em> ${f.description}</em><br/>` : ''}
        Factoid link:
        <a href="${f.uri}" target="_blank">${f.uri}</a>
        ${f.label ? `<br/>Related person: <em>${f.label}</em>` : ''}
        ${f.person ? `<br/>Related person link:<br/><a href="${f.person}" target="_blank">${f.person}</a>` : ''}
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
  state.selectedSourceKeywords.clear();
  document.querySelectorAll('input[name="gender"]').forEach(r => r.checked = r.value === '');
  document.querySelectorAll('input[name="uncertainty"]').forEach(r => r.checked = r.value === '');
  document.querySelectorAll('input[name="source"]').forEach(r => r.checked = r.value === '');

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
  // renderDefaultFactoids();
}

// Master updater
function updateResults() {
  console.log("Updating results with state:", state);
  const queryString = stateToUrlParams(state);
  console.log("Generated query string:", queryString);
  const newUrl = `${window.location.pathname}?${queryString}`;
  history.replaceState(null, '', newUrl); // updates URL without reloading
  if (!queryString) {console.log("rendering default factoids");renderDefaultFactoids();}
  if (queryString.length > 1 && queryString !== '?' && queryString !== '?type=factoid') {
    fetchFactoidsByMultiType(state).then(renderFactoids);
  } else {
    renderDefaultFactoids();
  }
  
}


// Load dropdown menus
function setupDropdowns() {
  
  document.querySelectorAll('input[name="source"]').forEach(input => {
    input.addEventListener('change', () => {
      if (input.value) state.selectedSourceKeywords.add(input.value);
      updateResults();
    });
  });
  
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
  searchMenuItems('event-search', 'eventKeywordItems');
  searchMenuItems('relationship-search', 'relationshipKeywordItems');
  searchMenuItems('place-search', 'placeKeywordItems');
  renderDefaultFactoids();
}
  import allFactoidsData from "./types/factoid/defaultFactoids.json" with { type: 'json' };

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


async function renderDefaultFactoids() {
  const queryRestults = document.getElementById('factoidResults');
  queryRestults.classList.add('d-none');
  const factoidDisplay = document.getElementById('defaultFactoidResults');
  factoidDisplay.classList.remove('d-none');
  
  console.log("Rendering default factoids:", allFactoidsData);
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
 <h4>Factoids</h4>
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
