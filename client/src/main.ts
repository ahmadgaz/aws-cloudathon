// import './style.css'
// import typescriptLogo from './typescript.svg'
// import viteLogo from '/vite.svg'
// import { setupCounter } from './counter.ts'

document.querySelector<HTMLDivElement>('#app')!.innerHTML = '<h1>AnyCompany | Cloudathon SJSU</h1><div id="products"></div>';

async function fetchAndRenderProducts() {
  try {
    const res = await fetch('http://localhost:8000/products');
    const data = await res.json();
    const products = data.products || [];
    const productsHtml = `
      <h2>Products</h2>
      <ul>
        ${products.map((p: any) => `
          <li>
            <strong>${p.name}</strong> - $${p.price.toFixed(2)}<br/>
            <em>${p.description}</em><br/>
            <span>Stock: ${p.stock}</span>
          </li>
        `).join('')}
      </ul>
    `;
    document.getElementById('products')!.innerHTML = productsHtml;
  } catch (err) {
    document.getElementById('products')!.innerHTML = '<p>Failed to load products.</p>';
  }
}

fetchAndRenderProducts();
