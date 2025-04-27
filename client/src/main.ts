import './style.css'

interface Product {
  id: number;
  name: string;
  description: string;
  price: number;
  stock: number;
}

const app = document.querySelector<HTMLDivElement>('#app')!

app.innerHTML = `
  <nav class="top-navbar">
    <div class="nav-container">
      <div class="company-info">
        <h1>AnyCompany</h1>
        <span class="tagline">Cloudathon SJSU</span>
      </div>
      <div class="nav-links">
        <a href="#" class="active">
          <span class="nav-icon">🏠</span>
          <span class="nav-text">Products</span>
        </a>
        <a href="#">
          <span class="nav-icon">ℹ️</span>
          <span class="nav-text">About</span>
        </a>
        <a href="#">
          <span class="nav-icon">📞</span>
          <span class="nav-text">Contact</span>
        </a>
      </div>
    </div>
  </nav>

  <div class="container">
    <main>
      <div class="products-grid" id="products-container">
        <div class="loading">Loading products...</div>
      </div>
    </main>
  </div>

  <footer class="footer">
    <div class="footer-content">
      <div class="footer-left">
        <span class="footer-company">AnyCompany</span>
        <span class="footer-copyright">&copy; 2025</span>
      </div>
      <div class="footer-right">
        <a href="#" class="footer-link">📧 info@anycompany.com</a>
        <a href="#" class="footer-link">📱 (123) 456-7890</a>
      </div>
    </div>
  </footer>
`

async function fetchProducts() {
  try {
    // Use VITE_API_BASE_URL for flexibility; fallback to localhost for dev
    const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000';
    // For production, set VITE_API_BASE_URL to your ALB URL, e.g.:
    // VITE_API_BASE_URL="http://us-east-1-public-alb.elb.localhost.localstack.cloud:4566"
    const response = await fetch(`${API_BASE_URL}/products`)
    const data = await response.json()
    displayProducts(data.products)
  } catch (error) {
    console.error('Error fetching products:', error)
    const container = document.getElementById('products-container')!
    container.innerHTML = '<div class="error">Failed to load products. Please try again later.</div>'
  }
}

function displayProducts(products: Product[]) {
  const container = document.getElementById('products-container')!
  container.innerHTML = products.map(product => `
    <div class="product-card">
      <h2>${product.name}</h2>
      <p class="description">${product.description}</p>
      <div class="product-details">
        <span class="price">$${product.price.toFixed(2)}</span>
        <span class="stock">${product.stock} in stock</span>
      </div>
    </div>
  `).join('')
}

fetchProducts()
