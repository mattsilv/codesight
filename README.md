# CodeSight

[![ShellCheck](https://img.shields.io/badge/ShellCheck-Enabled-brightgreen.svg)](https://www.shellcheck.net)

CodeSight is a shell-based tool for analyzing code repositories to produce optimized context files for LLMs (Large Language Models). It helps extract the most relevant code for LLM prompts while managing token usage efficiently.

## Features

- Fast analysis of code repositories
- Intelligent gitignore-aware file traversal
- Customizable file extension filters
- Size and line count limits
- Pretty output formatting
- Visualization of code statistics

## Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/codesight.git
cd codesight

# Run the installer
./install.sh
```

Or quick installation:

```bash
curl -fsSL https://raw.githubusercontent.com/yourusername/codesight/main/install.sh | bash
```

## Usage

```bash
# Analysis command (default)
codesight [directory]

# Initialize in current directory
codesight init

# Show help
codesight help

# Show configuration info
codesight info

# Visualize code statistics
codesight visualize
```

### Analysis options

```
--output FILE      Specify output file (default: codesight.txt)
--extensions "EXT" Space-separated list of file extensions
--max-lines N      Maximum lines per file before truncation
--max-files N      Maximum files to include
--max-size N       Maximum file size in bytes
```

## Development

```bash
# Run tests
./tests/run_tests.sh

# Run ShellCheck to validate scripts
shellcheck *.sh */*.sh

# Fix common ShellCheck issues
./fix_shellcheck.sh --auto-fix

# Run pre-release checks
./pre_release.sh
```

## Code Quality

CodeSight uses ShellCheck for code quality and linting. Common standards include:

- ShellCheck compliance for all shell scripts
- Proper exit code handling and error reporting
- Thorough testing with automated validation
- User-friendly error messages
- Comprehensive documentation

## License

MIT

EXAMPLE USAGE

import React, { useState, useEffect } from 'react';
import { ChevronRight, ChevronLeft, Maximize, Minimize, ArrowLeft, ArrowRight, Smartphone, Monitor } from 'lucide-react';

const ResponsiveTable = ({ data, columns }) => {
const [viewMode, setViewMode] = useState('auto'); // 'auto', 'desktop', or 'mobile'
const [isMobile, setIsMobile] = useState(false);
const [activeColumns, setActiveColumns] = useState([0, 1]); // Start with first two columns
const [focusedRow, setFocusedRow] = useState(null);
const [compareMode, setCompareMode] = useState(false);

// Check viewport size
useEffect(() => {
const checkIsMobile = () => {
const autoDetected = window.innerWidth < 768;
setIsMobile(viewMode === 'auto' ? autoDetected : viewMode === 'mobile');
};

    checkIsMobile();
    window.addEventListener('resize', checkIsMobile);
    return () => window.removeEventListener('resize', checkIsMobile);

}, [viewMode]);

// Handle column navigation (mobile)
const shiftColumnsLeft = () => {
if (activeColumns[0] > 0) {
setActiveColumns(activeColumns.map(col => col - 1));
}
};

const shiftColumnsRight = () => {
if (activeColumns[1] < columns.length - 1) {
setActiveColumns(activeColumns.map(col => col + 1));
}
};

const toggleCompareMode = () => {
setCompareMode(!compareMode);
setFocusedRow(null);
};

// View mode toggle
const ViewModeToggle = () => (
<div className="flex justify-end mb-2 gap-2">
<div className="inline-flex bg-gray-100 rounded-lg p-1 shadow-sm">
<button
onClick={() => setViewMode('auto')}
className={`px-3 py-1 text-sm rounded-md flex items-center gap-1 ${
            viewMode === 'auto' ? 'bg-white shadow-sm' : 'text-gray-600'
          }`} >
<span>Auto</span>
</button>
<button
onClick={() => setViewMode('desktop')}
className={`px-3 py-1 text-sm rounded-md flex items-center gap-1 ${
            viewMode === 'desktop' ? 'bg-white shadow-sm' : 'text-gray-600'
          }`} >
<Monitor size={16} />
<span>Desktop</span>
</button>
<button
onClick={() => setViewMode('mobile')}
className={`px-3 py-1 text-sm rounded-md flex items-center gap-1 ${
            viewMode === 'mobile' ? 'bg-white shadow-sm' : 'text-gray-600'
          }`} >
<Smartphone size={16} />
<span>Mobile</span>
</button>
</div>
</div>
);

// If on desktop, render normal table
if (!isMobile) {
return (
<div className="w-full">
<ViewModeToggle />
<div className="overflow-x-auto w-full">
<table className="min-w-full bg-white shadow-md rounded-lg overflow-hidden">
<thead className="bg-gray-100">
<tr>
{columns.map((column, i) => (
<th key={i} className="px-4 py-3 text-left text-sm font-medium text-gray-700 uppercase tracking-wider">
{column.label}
</th>
))}
</tr>
</thead>
<tbody className="divide-y divide-gray-200">
{data.map((row, i) => (
<tr key={i} className={i % 2 === 0 ? 'bg-white' : 'bg-gray-50'}>
{columns.map((column, j) => (
<td key={j} className="px-4 py-2 text-sm text-gray-700">
{row[column.key]}
</td>
))}
</tr>
))}
</tbody>
</table>
</div>
</div>
);
}

// Mobile View
return (
<div className="w-full">
<ViewModeToggle />
<div className="w-full bg-white shadow-md rounded-lg overflow-hidden">
{/_ Mode Switch _/}
<div className="flex justify-between items-center bg-gray-100 px-4 py-2 border-b">
<h3 className="font-medium">
{compareMode ? 'Column Comparison' : 'Row Details'}
</h3>
<button 
          className="bg-blue-500 text-white p-2 rounded-full flex items-center"
          onClick={toggleCompareMode}
        >
{compareMode ? <Minimize size={16} /> : <Maximize size={16} />}
</button>
</div>

      {/* Column Comparison Mode */}
      {compareMode && (
        <div className="p-2">
          {/* Column Navigator */}
          <div className="flex justify-between items-center mb-4">
            <button
              onClick={shiftColumnsLeft}
              disabled={activeColumns[0] === 0}
              className={`p-2 rounded ${activeColumns[0] === 0 ? 'text-gray-400' : 'text-blue-500'}`}
            >
              <ChevronLeft size={20} />
            </button>

            <div className="text-center">
              <span className="text-sm text-gray-500">
                {activeColumns.map(i => columns[i].label).join(' & ')}
              </span>
            </div>

            <button
              onClick={shiftColumnsRight}
              disabled={activeColumns[1] >= columns.length - 1}
              className={`p-2 rounded ${activeColumns[1] >= columns.length - 1 ? 'text-gray-400' : 'text-blue-500'}`}
            >
              <ChevronRight size={20} />
            </button>
          </div>

          {/* Visible Columns */}
          <div className="space-y-2">
            {data.map((row, i) => (
              <div
                key={i}
                className="flex bg-gray-50 rounded-lg overflow-hidden shadow-sm"
              >
                {activeColumns.map((colIndex, j) => (
                  <div
                    key={j}
                    className={`flex-1 p-3 ${j === 0 ? 'bg-gray-100' : 'bg-white'}`}
                  >
                    <div className="text-xs text-gray-500 mb-1">
                      {columns[colIndex].label}
                    </div>
                    <div className="font-medium">
                      {row[columns[colIndex].key]}
                    </div>
                  </div>
                ))}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Detailed Row Mode */}
      {!compareMode && (
        <div>
          {/* Row Selector */}
          <div className="flex justify-between items-center px-4 py-2 border-b bg-gray-50">
            <button
              onClick={() => setFocusedRow(Math.max(0, (focusedRow ?? 0) - 1))}
              disabled={focusedRow === 0}
              className={`p-1 ${focusedRow === 0 ? 'text-gray-400' : 'text-blue-500'}`}
            >
              <ArrowLeft size={18} />
            </button>

            <div className="text-sm">
              Row {(focusedRow ?? 0) + 1} of {data.length}
            </div>

            <button
              onClick={() => setFocusedRow(Math.min(data.length - 1, (focusedRow ?? 0) + 1))}
              disabled={focusedRow === data.length - 1}
              className={`p-1 ${focusedRow === data.length - 1 ? 'text-gray-400' : 'text-blue-500'}`}
            >
              <ArrowRight size={18} />
            </button>
          </div>

          {/* Row Details */}
          <div className="p-4 space-y-3">
            {columns.map((column, i) => (
              <div key={i} className="flex justify-between border-b pb-2">
                <div className="font-medium text-gray-600">{column.label}</div>
                <div className="text-right">{data[focusedRow ?? 0][column.key]}</div>
              </div>
            ))}
          </div>
        </div>
      )}
      </div>
    </div>

);
};

// Sample data for preview
const sampleColumns = [
{ key: 'product', label: 'Product' },
{ key: 'price', label: 'Price' },
{ key: 'stock', label: 'Stock' },
{ key: 'sales', label: 'Sales' },
{ key: 'rating', label: 'Rating' },
{ key: 'profit', label: 'Profit' }
];

const sampleData = [
{ product: 'Laptop Pro', price: '$1,299', stock: '34', sales: '421', rating: '4.8', profit: '$546' },
{ product: 'SmartPhone X', price: '$899', stock: '128', sales: '914', rating: '4.6', profit: '$325' },
{ product: 'Tablet Mini', price: '$499', stock: '59', sales: '210', rating: '4.2', profit: '$124' },
{ product: 'Gaming Console', price: '$399', stock: '12', sales: '172', rating: '4.9', profit: '$83' },
{ product: 'Wireless Headphones', price: '$199', stock: '87', sales: '325', rating: '4.5', profit: '$67' },
{ product: 'Smart Watch', price: '$299', stock: '45', sales: '118', rating: '4.1', profit: '$92' }
];

const MobileTableDemo = () => {
return (
<div className="w-full max-w-4xl mx-auto p-4">
<h2 className="text-xl font-bold mb-4 text-center">Product Performance Dashboard</h2>
<ResponsiveTable data={sampleData} columns={sampleColumns} />
</div>
);
};

export default MobileTableDemo;
