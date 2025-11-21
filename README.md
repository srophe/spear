# SPEAR - Syriaca Prosopographical Event Analysis and Research

A modern web application for exploring prosopographical data from the Syriaca.org project, built with vanilla JavaScript and SPARQL queries.

## Overview

SPEAR provides an interactive interface for searching and analyzing historical persons, events, and relationships from Syriac sources. The application uses SPARQL queries against a Neptune database with a publicly accessible API to enable complex multi-faceted searches.

## Features

### Multi-Modal Search
- **Person Search**: Find individuals by name, occupation, gender, relationships, and associated places
- **Event Search**: Explore historical events with filtering by participants, locations, and keywords

### Advanced Filtering
- **Multi-select filters**: Combine multiple criteria (events, relationships, places, occupations)
- **Source filtering**: Filter by specific historical sources (Letters of Severus, Lives of Eastern Saints, Chronicle of Edessa)
- **Uncertainty analysis**: Filter by certainty levels of historical claims
- **Geographic filtering**: Search by birth places, death places, residences, and event locations

### Performance Optimizations
- **Query timeout handling**: 15-second timeout prevents hanging requests
- **Result limiting**: Maximum 500 results per query for optimal performance
- **POST requests**: Eliminates URL length restrictions for complex queries
- **Debounced search**: Reduces server load during typing

## Technical Architecture

### Frontend
- **Vanilla JavaScript**: No framework dependencies
- **Modular design**: Separate modules for persons, events, and factoids
- **Responsive UI**: Bootstrap-based interface with collapsible filters
- **URL state management**: Shareable URLs with filter parameters

### Backend Integration
- **SPARQL Protocol**: Standard SPARQL queries via POST requests
- **Neptune compatibility**: Optimized for AWS Neptune SPARQL endpoint
- **Content-Type**: `application/sparql-query` for proper SPARQL handling
- **Error handling**: Graceful degradation on query failures or timeouts

## Getting Started

### Prerequisites
- Modern web browser with JavaScript enabled
- Access to SPARQL endpoint (configured in `person/search.js`)

### Installation
1. Clone the repository
2. Update `SPARQL_ENDPOINT` in search modules to point to your endpoint
3. Serve files via HTTP server (required for CORS)

### Usage
1. Open `browse.html` in your browser
2. Select search mode (Person, Event, or Factoid)
3. Apply filters using the sidebar controls
4. View results in the main content area
5. Share searches via URL parameters

## Configuration

### SPARQL Endpoint
Update the endpoint URL in:
- `person/search.js`
- `event/search.js` 
- `factoid/search.js`

### Query Limits
Adjust performance settings:
- `LIMIT 500`: Maximum results per query
- `15000ms`: Query timeout duration
- Filter size limits for complex queries

## Data Sources

The application queries data from:
- **SPEAR Prosopography Graph**: `https://spear-prosop.org`
- **Syriaca Persons Graph**: `http://syriaca.org/persons#graph`
- **Source collections**: Letters of Severus, Lives of Eastern Saints, Chronicle of Edessa

## Browser Support

- Chrome/Edge 88+
- Firefox 85+
- Safari 14+

Requires support for:
- Fetch API with AbortController
- ES6 modules
- CSS Grid/Flexbox

## Performance Notes

- Queries are limited to prevent timeouts
- Complex multi-filter searches may take 5-15 seconds
- Source filters are limited to prevent overly broad queries
- Results are paginated at 500 items maximum

## Development

### File Structure
```
spear/
├── browse.html          # Main application entry point
├── modes/
│   ├── person.js        # Person search interface
│   ├── event.js         # Event search interface
│   └── factoid.js       # Factoid search interface
├── person/
│   └── search.js        # Person SPARQL queries
├── event/
│   └── search.js        # Event SPARQL queries
└── factoid/
    └── search.js        # Factoid SPARQL queries
```

### Adding New Filters
1. Add UI elements to the appropriate mode file
2. Update the filter state object
3. Modify the SPARQL query builder
4. Add URL parameter handling

## License

Open source - see original Srophé Application license terms.