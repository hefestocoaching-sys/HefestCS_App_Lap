#!/usr/bin/env python3
"""
Script para corregir encoding UTF-8 corrupto en exercise_catalog_gym.json
Autor: Hefesto Coaching System
Fecha: 2026-02-12
"""

import json
import sys
from pathlib import Path


def fix_corrupted_text(text):
    """
    Corrige caracteres UTF-8 mal codificados.

    Patrón detectado:
    - Ã³ → ó
    - Ã¡ → á
    - Ã­ → í
    - Ãº → ú
    - Ã© → é
    - Ã±  → ñ
    """
    if not isinstance(text, str):
        return text

    replacements = {
        'Ã³': 'ó',
        'Ã¡': 'á',
        'Ã­': 'í',
        'Ãº': 'ú',
        'Ã©': 'é',
        'Ã±': 'ñ',
        'Ã': 'Á',
        'Ã‰': 'É',
        'Ã': 'Í',
        'Ã"': 'Ó',
        'Ãš': 'Ú',
        "Ã'": 'Ñ',
    }

    result = text
    for wrong, correct in replacements.items():
        result = result.replace(wrong, correct)

    return result


def fix_exercise_names(data):
    """Recorre recursivamente el JSON y corrige todos los nombres."""
    if isinstance(data, dict):
        for key, value in data.items():
            if key == 'es' and isinstance(value, str):
                data[key] = fix_corrupted_text(value)
            else:
                fix_exercise_names(value)
    elif isinstance(data, list):
        for item in data:
            fix_exercise_names(item)

    return data


def main():
    # Ruta al archivo
    file_path = Path('assets/data/exercises/exercise_catalog_gym.json')

    if not file_path.exists():
        print(f"❌ ERROR: No se encontró el archivo {file_path}")
        sys.exit(1)

    print(f"📂 Leyendo archivo: {file_path}")

    # Leer con encoding UTF-8 (incluso si está corrupto)
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except (UnicodeDecodeError, json.JSONDecodeError):
        # Intentar con utf-8-sig por BOM o latin-1 si falla
        try:
            print("⚠️  UTF-8 falló, intentando con utf-8-sig...")
            with open(file_path, 'r', encoding='utf-8-sig') as f:
                data = json.load(f)
        except (UnicodeDecodeError, json.JSONDecodeError):
            print("⚠️  utf-8-sig falló, intentando con latin-1...")
            with open(file_path, 'r', encoding='latin-1') as f:
                data = json.load(f)

    print(f"✅ Archivo cargado: {len(data.get('exercises', []))} ejercicios")

    # Contar corrupciones antes
    corrupted_count = 0
    for exercise in data.get('exercises', []):
        name_es = exercise.get('name', {}).get('es', '')
        if 'Ã' in name_es:
            corrupted_count += 1

    print(f"🔍 Detectados {corrupted_count} ejercicios con encoding corrupto")

    # Aplicar corrección
    print("🔧 Aplicando correcciones...")
    fixed_data = fix_exercise_names(data)

    # Verificar correcciones
    fixed_count = 0
    for exercise in fixed_data.get('exercises', []):
        name_es = exercise.get('name', {}).get('es', '')
        if 'Ã' not in name_es and any(c in name_es for c in 'áéíóúñ'):
            fixed_count += 1

    print(f"✅ Corregidos {fixed_count} nombres")

    # Guardar archivo corregido
    backup_path = file_path.with_suffix('.json.backup')
    print(f"💾 Creando backup en: {backup_path}")
    with open(backup_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"💾 Guardando archivo corregido: {file_path}")
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(fixed_data, f, ensure_ascii=False, indent=2)

    print("\n🎉 ¡Corrección completada!")
    print(f"   - Backup guardado en: {backup_path}")
    print(f"   - Archivo corregido: {file_path}")
    print(f"   - Total corregido: {fixed_count} nombres")


if __name__ == '__main__':
    main()
