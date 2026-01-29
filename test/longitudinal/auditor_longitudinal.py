#!/usr/bin/env python3
"""
AUDITOR LONGITUDINAL - MOTOR DE ENTRENAMIENTO HCS

Evalúa si el motor toma decisiones correctas, conservadoras y coherentes
a lo largo del tiempo, basándose únicamente en outputs serializados (JSON)
y DecisionTrace.

Metodología:
1. Reconstrucción temporal
2. Evaluación por INVARIANTES
3. Direccionalidad
4. Estabilidad  
5. Reversibilidad
6. Uso del fallo muscular
7. Trazabilidad
"""

import json
import glob
from dataclasses import dataclass
from typing import List, Dict, Any, Optional
from pathlib import Path


@dataclass
class WeekData:
    """Datos extraídos de un JSON semanal"""
    week_number: int
    feedback: Optional[Dict[str, Any]]
    phase: str
    fatigue_expectation: str
    rir_target: float
    volume_by_muscle: Dict[str, int]  # sets totales por músculo
    allow_failure_count: int
    allow_failure_exercises: List[str]
    intensification_count: int
    decisions: List[Dict[str, Any]]
    raw_data: Dict[str, Any]


class LongitudinalAuditor:
    """Auditor científico-técnico del motor de entrenamiento"""

    def __init__(self, json_dir: str):
        self.json_dir = Path(json_dir)
        self.weeks: List[WeekData] = []
        self.violations: List[Dict[str, Any]] = []
        self.scores = {
            'scientific': 0,
            'clinical': 0,
            'robustness': 0
        }

    def load_weeks(self):
        """Carga y parsea todos los JSON de semanas"""
        json_files = sorted(glob.glob(str(self.json_dir / "week_*.json")))
        
        for filepath in json_files:
            with open(filepath, 'r', encoding='utf-8') as f:
                data = json.load(f)
                week = self._parse_week(data)
                self.weeks.append(week)
        
        print(f"✅ Cargadas {len(self.weeks)} semanas\n")

    def _parse_week(self, data: Dict[str, Any]) -> WeekData:
        """Extrae datos relevantes de un JSON semanal"""
        week_num = data['weekNumber']
        feedback = data.get('feedbackInput')
        plan = data['plan']
        decisions = data['decisions']

        # Extraer fase y RIR de decisions
        phase = "unknown"
        fatigue_exp = "normal"
        rir_target = 2.5

        for d in decisions:
            if d.get('category') == 'week_setup':
                ctx = d.get('context', {})
                phase = ctx.get('phase', phase)
                fatigue_exp = ctx.get('fatigueExpectation', fatigue_exp)
                rir_target = ctx.get('rirTarget', rir_target)
                break

        # Calcular volumen por músculo
        volume_by_muscle = {}
        allow_failure_count = 0
        allow_failure_exercises = []
        intensification_count = 0

        for week in plan.get('weeks', []):
            for session in week.get('sessions', []):
                for prescription in session.get('prescriptions', []):
                    muscle = prescription.get('muscleGroup', {}).get('name', 'unknown')
                    sets = prescription.get('sets', 0)
                    
                    volume_by_muscle[muscle] = volume_by_muscle.get(muscle, 0) + sets
                    
                    if prescription.get('allowFailureOnLastSet', False):
                        allow_failure_count += 1
                        exercise = prescription.get('exercise', {}).get('name', 'unknown')
                        allow_failure_exercises.append(exercise)
                    
                    if prescription.get('techniques'):
                        intensification_count += 1

        return WeekData(
            week_number=week_num,
            feedback=feedback,
            phase=phase,
            fatigue_expectation=fatigue_exp,
            rir_target=rir_target,
            volume_by_muscle=volume_by_muscle,
            allow_failure_count=allow_failure_count,
            allow_failure_exercises=allow_failure_exercises,
            intensification_count=intensification_count,
            decisions=decisions,
            raw_data=data
        )

    def reconstruct_timeline(self):
        """1️⃣ Reconstrucción temporal"""
        print("=" * 80)
        print("1️⃣ RECONSTRUCCIÓN TEMPORAL")
        print("=" * 80)
        
        for week in self.weeks:
            # Estado basado en feedback
            if week.feedback:
                fatigue = week.feedback.get('fatigue', 5.0)
                adherence = week.feedback.get('adherence', 1.0)
                
                if fatigue >= 8.0:
                    estado = "🔴 FATIGA ALTA"
                elif fatigue >= 6.0:
                    estado = "🟡 FATIGA MODERADA"
                elif adherence < 0.75:
                    estado = "🟡 ADHERENCIA BAJA"
                else:
                    estado = "🟢 PROGRESIÓN"
            else:
                estado = "⚪ SIN FEEDBACK"
            
            # Fase programada
            if week.phase == "deload":
                estado += " → DELOAD"
            elif week.phase == "intensification":
                estado += " → INTENSIFICACIÓN"
            
            print(f"Semana {week.week_number:2d}: {estado:30s} | "
                  f"RIR={week.rir_target:.1f} | "
                  f"Fallo={week.allow_failure_count} | "
                  f"Vol chest={week.volume_by_muscle.get('chest', 0):2d}")

        print()

    def check_invariants(self):
        """2️⃣ Evaluación por INVARIANTES (reglas que NO se deben romper)"""
        print("=" * 80)
        print("2️⃣ EVALUACIÓN POR INVARIANTES")
        print("=" * 80)
        
        # MRV teóricos (basados en profile intermedio)
        MRV = {
            'chest': 22, 'back': 25, 'shoulders': 20,
            'quads': 20, 'hamstrings': 16, 'glutes': 18,
            'biceps': 14, 'triceps': 18
        }

        for week in self.weeks:
            # INVARIANTE 1: Volumen semanal > MRV
            for muscle, sets in week.volume_by_muscle.items():
                mrv = MRV.get(muscle, 25)
                if sets > mrv:
                    self._add_violation(
                        week=week.week_number,
                        muscle=muscle,
                        rule="Volumen > MRV",
                        severity="P0",
                        details=f"Sets={sets} > MRV={mrv}"
                    )

            # INVARIANTE 2: Fallo en deload
            if week.phase == "deload" and week.allow_failure_count > 0:
                self._add_violation(
                    week=week.week_number,
                    muscle="N/A",
                    rule="Fallo en deload",
                    severity="P0",
                    details=f"{week.allow_failure_count} ejercicios con allowFailure en deload"
                )

            # INVARIANTE 3: Fallo en fatiga alta
            if week.fatigue_expectation == "high" and week.allow_failure_count > 0:
                self._add_violation(
                    week=week.week_number,
                    muscle="N/A",
                    rule="Fallo en fatigue=high",
                    severity="P0",
                    details=f"{week.allow_failure_count} ejercicios con allowFailure"
                )

            # INVARIANTE 4: Progresión tras fatiga alta
            if week.week_number > 1:
                prev_week = self.weeks[week.week_number - 2]
                if prev_week.feedback and prev_week.feedback.get('fatigue', 5.0) >= 8.0:
                    # Debe haber reducción o mantenimiento, NO progresión
                    for muscle in week.volume_by_muscle:
                        curr_vol = week.volume_by_muscle.get(muscle, 0)
                        prev_vol = prev_week.volume_by_muscle.get(muscle, 0)
                        
                        if curr_vol > prev_vol * 1.1:  # Aumento > 10%
                            self._add_violation(
                                week=week.week_number,
                                muscle=muscle,
                                rule="Progresión tras fatiga alta",
                                severity="P1",
                                details=f"Vol aumentó {prev_vol}→{curr_vol} después de fatiga={prev_week.feedback.get('fatigue')}"
                            )

        if len(self.violations) == 0:
            print("✅ SIN VIOLACIONES DETECTADAS")
        else:
            for v in self.violations:
                print(f"❌ Semana {v['week']:2d} | {v['muscle']:12s} | "
                      f"{v['rule']:30s} | {v['severity']} | {v['details']}")
        
        print()

    def check_directionality(self):
        """3️⃣ Evaluación de DIRECCIONALIDAD"""
        print("=" * 80)
        print("3️⃣ EVALUACIÓN DE DIRECCIONALIDAD")
        print("=" * 80)
        
        progressions = 0
        regressions = 0
        maintains = 0

        for i in range(1, len(self.weeks)):
            week = self.weeks[i]
            prev = self.weeks[i - 1]
            
            if not prev.feedback:
                continue
            
            fatigue = prev.feedback.get('fatigue', 5.0)
            adherence = prev.feedback.get('adherence', 1.0)
            
            # Volumen promedio
            curr_avg = sum(week.volume_by_muscle.values()) / max(len(week.volume_by_muscle), 1)
            prev_avg = sum(prev.volume_by_muscle.values()) / max(len(prev.volume_by_muscle), 1)
            
            delta = curr_avg - prev_avg
            
            # Clasificar señales
            if fatigue >= 8.0 or adherence < 0.75:
                signal = "NEGATIVA"
                expected = "REDUCIR"
            elif fatigue <= 5.0 and adherence >= 0.85:
                signal = "POSITIVA"
                expected = "PROGRESAR/MANTENER"
            else:
                signal = "AMBIGUA"
                expected = "MANTENER"
            
            # Clasificar respuesta
            if delta > 2:
                response = "PROGRESIÓN"
                progressions += 1
            elif delta < -2:
                response = "REDUCCIÓN"
                regressions += 1
            else:
                response = "MANTIENE"
                maintains += 1
            
            coherent = "✅" if self._is_coherent(signal, response) else "❌"
            
            print(f"Semana {prev.week_number}→{week.week_number}: "
                  f"Señal={signal:12s} | Respuesta={response:12s} | "
                  f"ΔVol={delta:+5.1f} | {coherent}")

        print(f"\n📊 Resumen: {progressions} progresiones, {maintains} mantiene, {regressions} reducciones")
        print()

    def _is_coherent(self, signal: str, response: str) -> bool:
        """Verifica coherencia entre señal y respuesta"""
        if signal == "NEGATIVA":
            return response in ["REDUCCIÓN", "MANTIENE"]
        elif signal == "POSITIVA":
            return response in ["PROGRESIÓN", "MANTIENE"]
        else:  # AMBIGUA
            return True  # Cualquier respuesta es válida

    def check_stability(self):
        """4️⃣ Evaluación de ESTABILIDAD"""
        print("=" * 80)
        print("4️⃣ EVALUACIÓN DE ESTABILIDAD")
        print("=" * 80)
        
        # Calcular varianza de volumen semanal
        chest_volumes = [w.volume_by_muscle.get('chest', 0) for w in self.weeks]
        back_volumes = [w.volume_by_muscle.get('back', 0) for w in self.weeks]
        
        chest_variance = self._variance(chest_volumes)
        back_variance = self._variance(back_volumes)
        
        print(f"Varianza volumen chest: {chest_variance:.2f}")
        print(f"Varianza volumen back:  {back_variance:.2f}")
        
        # Buscar oscilaciones caóticas (cambios > 30% semana a semana)
        chaotic_weeks = 0
        for i in range(1, len(self.weeks)):
            for muscle in ['chest', 'back', 'quads']:
                curr = self.weeks[i].volume_by_muscle.get(muscle, 0)
                prev = self.weeks[i-1].volume_by_muscle.get(muscle, 0)
                
                if prev > 0:
                    change_pct = abs(curr - prev) / prev
                    if change_pct > 0.3:
                        chaotic_weeks += 1
                        print(f"⚠️  Semana {i}: {muscle} cambió {change_pct*100:.0f}% ({prev}→{curr})")
                        break

        if chaotic_weeks == 0:
            print("✅ Sin oscilaciones caóticas detectadas")
        
        print()

    def _variance(self, values: List[float]) -> float:
        """Calcula varianza de una lista"""
        if len(values) < 2:
            return 0.0
        mean = sum(values) / len(values)
        return sum((x - mean) ** 2 for x in values) / len(values)

    def check_reversibility(self):
        """5️⃣ Evaluación de REVERSIBILIDAD"""
        print("=" * 80)
        print("5️⃣ EVALUACIÓN DE REVERSIBILIDAD")
        print("=" * 80)
        
        # Buscar ciclos de reducción → recuperación
        for i in range(2, len(self.weeks)):
            w_minus_2 = self.weeks[i - 2]
            w_minus_1 = self.weeks[i - 1]
            w_current = self.weeks[i]
            
            # Buscar patrón: alto → bajo → recuperación
            if w_minus_2.feedback and w_minus_2.feedback.get('fatigue', 5.0) >= 8.0:
                vol_before = sum(w_minus_2.volume_by_muscle.values())
                vol_deload = sum(w_minus_1.volume_by_muscle.values())
                vol_after = sum(w_current.volume_by_muscle.values())
                
                reduced = vol_deload < vol_before * 0.8
                recovered = vol_after > vol_deload * 1.05
                
                if reduced and recovered:
                    print(f"✅ Semanas {w_minus_2.week_number}-{w_minus_1.week_number}-{w_current.week_number}: "
                          f"Ciclo reversible ({vol_before:.0f} → {vol_deload:.0f} → {vol_after:.0f})")

        print()

    def check_failure_usage(self):
        """6️⃣ Evaluación de USO DEL FALLO MUSCULAR"""
        print("=" * 80)
        print("6️⃣ EVALUACIÓN DE USO DEL FALLO")
        print("=" * 80)
        
        total_prescriptions = 0
        total_with_failure = 0
        
        for week in self.weeks:
            total_with_failure += week.allow_failure_count
            # Contar total de prescriptions
            for session in week.raw_data['plan'].get('weeks', [{}])[0].get('sessions', []):
                total_prescriptions += len(session.get('prescriptions', []))
        
        if total_prescriptions > 0:
            failure_rate = (total_with_failure / total_prescriptions) * 100
            print(f"📊 Tasa de fallo: {total_with_failure}/{total_prescriptions} ({failure_rate:.1f}%)")
            
            if failure_rate > 15:
                print("❌ Tasa de fallo > 15% (demasiado dominante)")
                self.scores['scientific'] -= 20
            elif failure_rate > 10:
                print("⚠️  Tasa de fallo 10-15% (moderada)")
                self.scores['scientific'] -= 10
            else:
                print("✅ Tasa de fallo < 10% (conservadora)")
                self.scores['scientific'] += 20

        # Verificar que nunca aparece en deload
        for week in self.weeks:
            if week.phase == "deload" and week.allow_failure_count > 0:
                print(f"❌ Semana {week.week_number}: Fallo en deload")
                self.scores['scientific'] -= 30
        
        print()

    def check_traceability(self):
        """7️⃣ Evaluación de TRAZABILIDAD"""
        print("=" * 80)
        print("7️⃣ EVALUACIÓN DE TRAZABILIDAD")
        print("=" * 80)
        
        decisions_per_week = [len(w.decisions) for w in self.weeks]
        avg_decisions = sum(decisions_per_week) / len(decisions_per_week)
        
        print(f"📊 Promedio de DecisionTrace por semana: {avg_decisions:.1f}")
        
        # Verificar categorías clave
        required_categories = [
            'failure_policy_applied',
            'week_setup',
            'phase_periodization'
        ]
        
        for week in self.weeks:
            categories = {d.get('category') for d in week.decisions}
            missing = [cat for cat in required_categories if cat not in categories]
            
            if missing:
                print(f"⚠️  Semana {week.week_number}: Faltan categorías {missing}")
                self.scores['robustness'] -= 5
        
        if avg_decisions >= 30:
            print("✅ Trazabilidad completa (>30 decisiones/semana)")
            self.scores['robustness'] += 20
        else:
            print(f"⚠️  Trazabilidad limitada ({avg_decisions:.0f} decisiones/semana)")
        
        print()

    def calculate_scores(self):
        """Calcula scores finales"""
        # Base scores
        self.scores['scientific'] += 50  # Base
        self.scores['clinical'] += 50
        self.scores['robustness'] += 50

        # Penalizaciones por violaciones
        for v in self.violations:
            if v['severity'] == 'P0':
                self.scores['scientific'] -= 30
                self.scores['clinical'] -= 30
            elif v['severity'] == 'P1':
                self.scores['scientific'] -= 15
                self.scores['clinical'] -= 15

        # Clamp a 0-100
        for key in self.scores:
            self.scores[key] = max(0, min(100, self.scores[key]))

    def generate_report(self):
        """Genera reporte final"""
        print("=" * 80)
        print("📋 REPORTE FINAL")
        print("=" * 80)
        
        # Scores
        print("\n1️⃣ SCORE LONGITUDINAL (0-100)")
        print(f"   Científico: {self.scores['scientific']}/100")
        print(f"   Clínico:    {self.scores['clinical']}/100")
        print(f"   Robustez:   {self.scores['robustness']}/100")
        
        avg_score = sum(self.scores.values()) / 3
        
        # Tabla temporal
        print("\n2️⃣ TABLA DE EVALUACIÓN TEMPORAL")
        print(f"{'Semana':<8} {'Estado':<25} {'Riesgo':<10} {'Comentario'}")
        print("-" * 80)
        
        for week in self.weeks:
            if week.feedback:
                fatigue = week.feedback.get('fatigue', 5.0)
                if fatigue >= 8.0:
                    estado = "FATIGA ALTA"
                    riesgo = "ALTO"
                elif fatigue >= 6.0:
                    estado = "FATIGA MODERADA"
                    riesgo = "MEDIO"
                else:
                    estado = "NORMAL"
                    riesgo = "BAJO"
            else:
                estado = "SIN FEEDBACK"
                riesgo = "N/A"
            
            comentario = f"Phase={week.phase}, RIR={week.rir_target:.1f}"
            print(f"{week.week_number:<8} {estado:<25} {riesgo:<10} {comentario}")
        
        # Violaciones
        print("\n3️⃣ LISTA DE VIOLACIONES")
        if len(self.violations) == 0:
            print("   ✅ SIN VIOLACIONES")
        else:
            for v in self.violations:
                print(f"   • Semana {v['week']}: {v['rule']} ({v['severity']}) - {v['details']}")
        
        # Veredicto
        print("\n4️⃣ VEREDICTO FINAL")
        if avg_score >= 80 and len([v for v in self.violations if v['severity'] == 'P0']) == 0:
            verdict = "✅ ENTRENAMIENTO CORRECTO Y SEGURO A LARGO PLAZO"
        elif avg_score >= 60:
            verdict = "⚠️  ENTRENAMIENTO USABLE CON RIESGO CONTROLADO"
        else:
            verdict = "❌ ENTRENAMIENTO INCORRECTO O PELIGROSO"
        
        print(f"   {verdict}")
        
        # Justificación
        print("\n5️⃣ JUSTIFICACIÓN FINAL")
        
        if avg_score >= 80:
            print("   El motor demuestra un comportamiento conservador y científicamente")
            print("   alineado a lo largo del tiempo. Las progresiones son graduales,")
            print("   el uso del fallo es selectivo, y el sistema responde apropiadamente")
            print("   a señales de fatiga con reducciones oportunas. La trazabilidad es")
            print("   completa y las decisiones son defendibles. El motor es APTO para")
            print("   uso real continuo sin supervisión adicional.")
        elif avg_score >= 60:
            print("   El motor muestra comportamiento mayormente correcto pero con")
            print("   algunas inconsistencias menores. Las progresiones son razonables")
            print("   pero ocasionalmente excesivas. El uso del fallo está presente pero")
            print("   no dominante. Se recomienda monitoreo clínico durante las primeras")
            print("   semanas de uso real. USABLE CON PRECAUCIÓN.")
        else:
            print("   El motor presenta VIOLACIONES CRÍTICAS de invariantes científicos.")
            print("   Se detectaron progresiones excesivas tras señales de fatiga alta,")
            print("   uso inapropiado del fallo muscular, o falta de mecanismos de")
            print("   protección. NO APTO para uso real sin correcciones mayores.")
        
        print("\n" + "=" * 80)

    def _add_violation(self, week: int, muscle: str, rule: str, severity: str, details: str):
        """Agrega una violación a la lista"""
        self.violations.append({
            'week': week,
            'muscle': muscle,
            'rule': rule,
            'severity': severity,
            'details': details
        })

    def run_audit(self):
        """Ejecuta auditoría completa"""
        self.load_weeks()
        self.reconstruct_timeline()
        self.check_invariants()
        self.check_directionality()
        self.check_stability()
        self.check_reversibility()
        self.check_failure_usage()
        self.check_traceability()
        self.calculate_scores()
        self.generate_report()


if __name__ == "__main__":
    auditor = LongitudinalAuditor("test/longitudinal/output")
    auditor.run_audit()
