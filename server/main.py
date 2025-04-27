import os
from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.exc import SQLAlchemyError
from starlette.responses import JSONResponse
from sqlalchemy import text

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+asyncpg://postgres:postgres@postgres:5432/postgres"
)

engine = create_async_engine(DATABASE_URL, pool_size=10, max_overflow=20, pool_timeout=30)
async_session = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

async def get_db():
    async with async_session() as session:
        yield session

@app.get("/")
def root():
    return {"status": "ok"}

@app.get("/health")
async def health(db: AsyncSession = Depends(get_db)):
    try:
        await db.execute(text("SELECT 1"))
        return {"status": "ok"}
    except SQLAlchemyError as e:
        return JSONResponse(status_code=500, content={"status": "error", "detail": str(e)})

@app.get("/db-connection")
async def db_connection(db: AsyncSession = Depends(get_db)):
    try:
        await db.execute(text("SELECT 1"))
        return {"status": "connected", "detail": "Database connection successful."}
    except SQLAlchemyError as e:
        return JSONResponse(status_code=500, content={"status": "error", "detail": str(e)})

@app.get("/products")
async def get_products(db: AsyncSession = Depends(get_db)):
    try:
        result = await db.execute(text("SELECT id, name, description, price, stock FROM products"))
        products = [
            {
                "id": row.id,
                "name": row.name,
                "description": row.description,
                "price": float(row.price),
                "stock": row.stock
            }
            for row in result.fetchall()
        ]
        return {"products": products}
    except SQLAlchemyError as e:
        return JSONResponse(status_code=500, content={"status": "error", "detail": str(e)}) 