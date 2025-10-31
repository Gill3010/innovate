import os
import logging
from flask import Blueprint, request, jsonify
from backend.extensions import limiter, cache
from pydantic import BaseModel, Field, ValidationError
from openai import OpenAI, APIError, AuthenticationError

ai_bp = Blueprint("ai", __name__)
_client = None


def _client_lazy():
    global _client
    if _client is None:
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            raise ValueError("OPENAI_API_KEY no está configurada")
        # Inicializar sin proxies para evitar conflictos
        _client = OpenAI(
            api_key=api_key,
            timeout=60.0,
            max_retries=2
        )
    return _client


class ProjectDescInput(BaseModel):
    title: str = Field(default="")
    tech: str = Field(default="")
    highlights: str = Field(default="")


@ai_bp.post("/project-description")
@limiter.limit("20/minute")
@cache.cached(timeout=300)
def project_description():
    payload = request.get_json() or {}
    data = ProjectDescInput(**payload)
    client = _client_lazy()
    prompt = (
        "Escribe una descripción clara y atractiva para un proyecto del portafolio. "
        f"Título: {data.title}. Tecnologías: {data.tech}. Logros: {data.highlights}. "
        "Devuelve 2 párrafos breves con enfoque en impacto y retos."
    )
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.7,
    )
    text = resp.choices[0].message.content
    return jsonify({"description": text})


class CVImproveInput(BaseModel):
    resume_text: str
    target_role: str = ""


@ai_bp.post("/cv-suggestions")
@limiter.limit("20/minute")
def cv_suggestions():
    payload = request.get_json() or {}
    data = CVImproveInput(**payload)
    client = _client_lazy()
    prompt = (
        "Mejora este CV con sugerencias concretas, bullets reescritos y métricas. "
        f"Rol objetivo: {data.target_role}. CV:\n{data.resume_text}"
    )
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.4,
    )
    text = resp.choices[0].message.content
    return jsonify({"suggestions": text})


class CoverLetterInput(BaseModel):
    resume_text: str
    job_desc: str
    company: str = ""


@ai_bp.post("/cover-letter")
@limiter.limit("20/minute")
def cover_letter():
    payload = request.get_json() or {}
    data = CoverLetterInput(**payload)
    client = _client_lazy()
    prompt = (
        "Redacta una carta de presentación breve y personalizada (<= 200 palabras). "
        f"Empresa: {data.company}. Puesto: según esta descripción: {data.job_desc}. "
        f"Usa este CV como base: {data.resume_text}."
    )
    resp = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.5,
    )
    text = resp.choices[0].message.content
    return jsonify({"cover_letter": text})


class CareerChatInput(BaseModel):
    message: str


@ai_bp.post("/career-chat")
@limiter.limit("60/minute")
def career_chat():
    try:
        payload = request.get_json() or {}
        data = CareerChatInput(**payload)
        
        # Verificar que la API key esté configurada
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key or api_key.strip() == "":
            return jsonify({"error": "OPENAI_API_KEY no está configurada. Por favor, configura la variable de entorno OPENAI_API_KEY."}), 500
        
        client = _client_lazy()
        system = "Eres un asesor laboral experto. Responde en español, breve y accionable."
        resp = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system},
                {"role": "user", "content": data.message},
            ],
            temperature=0.6,
        )
        text = resp.choices[0].message.content
        return jsonify({"reply": text})
    except ValidationError as e:
        logging.error(f"Validation error in career-chat: {e}")
        return jsonify({"error": f"Error en los datos: {str(e)}"}), 400
    except AuthenticationError as e:
        logging.error(f"OpenAI authentication error: {e}")
        return jsonify({"error": "Error de autenticación con OpenAI. Verifica que tu OPENAI_API_KEY sea válida."}), 401
    except APIError as e:
        logging.error(f"OpenAI API error: {e}")
        return jsonify({"error": f"Error en la API de OpenAI: {str(e)}"}), 500
    except Exception as e:
        logging.exception(f"Unexpected error in career-chat: {e}")
        return jsonify({"error": f"Error inesperado: {str(e)}"}), 500
