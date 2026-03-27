# A12 - TABLA DE VERDAD FORENSE

## Matriz observada (assertion vs evidencia)

| Assertion auditada | Evidencia en codigo real | Veredicto |
|---|---|---|
| La app es local-first para cliente | saveClient guarda local primero y luego push remoto debounce | VERDADERO |
| El sync de cola garantiza entrega remota efectiva | _syncItem no implementa push real completo | FALSO |
| Training records se sincronizan remoto granularmente | pushTrainingRecord retorna sin ejecutar push | FALSO |
| Permission-denied solo afecta evento puntual | _remoteSyncTemporarilyDisabled corta sync de sesion | FALSO |
| Existe unica ruta Firestore para appointments | hay ruta flat y ruta coaches/{uid}/appointments | FALSO |
| Existe unica ruta Firestore para transactions | hay ruta flat y ruta coaches/{uid}/transactions | FALSO |
| AuthGate falla duro si Firebase no esta listo | degrada a LoginScreen en catch | FALSO |
| Shell guarda cambios sucios antes de cambiar cliente | _saveActiveModuleIfNeeded recorre _allModules y saveIfDirty | VERDADERO |
| Nutricion versiona planes en snapshots | NutritionPlanRepository crea PlanSnapshot con version | VERDADERO |
| Entrenamiento persiste plan en cliente tras generar | training_plan_provider hace saveClient(clientWithPlan) | VERDADERO |

## Nota
- Veredicto FALSO aqui significa "assertion no soportada por evidencia", no implica bug funcional inmediato en todos los casos.
