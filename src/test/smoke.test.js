const request = require('supertest');
const app = require('../index');
const { sequelize, Product } = require('../models');

describe('Smoke Test - Integración Efímera', () => {
  
  beforeAll(async () => {
    // En el pipeline, las migraciones se corren antes del test, 
    // pero aquí nos aseguramos de que la conexión sea válida.
    await sequelize.authenticate();
  });

  afterAll(async () => {
    await sequelize.close();
  });

  it('Debe responder 200 en el endpoint de salud', async () => {
    const res = await request(app).get('/health');
    expect(res.statusCode).toEqual(200);
    expect(res.body.status).toBe('UP');
  });

  it('Debe crear y listar un producto (Ciclo de vida de datos)', async () => {
    const newProduct = { name: 'Test Product', price: 99.99 };
    
    // Crear
    const postRes = await request(app)
      .post('/products')
      .send(newProduct);
    
    expect(postRes.statusCode).toEqual(201);
    expect(postRes.body.name).toBe(newProduct.name);

    // Listar
    const getRes = await request(app).get('/products');
    expect(getRes.statusCode).toEqual(200);
    expect(getRes.body.length).toBeGreaterThan(0);
    expect(getRes.body.some(p => p.name === newProduct.name)).toBeTruthy();
  });
});
