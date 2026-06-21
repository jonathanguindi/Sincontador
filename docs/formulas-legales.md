# Fórmulas legales de SinContador — para revisión de un abogado laboral

Este documento lista **cómo calcula la app cada concepto** para que un abogado
laboral panameño confirme que cada fórmula y constante es correcta según la ley
vigente. Junto a cada punto hay una **pregunta a validar**. (Yo soy un asistente
de software, no doy asesoría legal: esto necesita la firma de un profesional.)

Referencias en el código: `index.html`, funciones `calcularPago` (~línea 1771)
y `calcularLiquidacion` (~línea 1805); valores por defecto `LEYES_DEFAULT` (~1661).
Estos valores son **editables** por el usuario dentro de la app (pantalla de Leyes).

---

## 1. Valores por defecto (`LEYES_DEFAULT`)
| Concepto | Valor en la app | A validar |
|---|---|---|
| Salario mínimo Región 1 | $340.00 | ¿Vigente para trabajo doméstico en su región/categoría? |
| Salario mínimo Región 2 | $315.00 | Igual |
| CSS empleador | 13.25 % | ¿Tasa patronal vigente? |
| CSS empleado | 9.75 % | Ver punto 6 (hoy no se descarta al neto) |
| Seguro Educativo empleador | 1.50 % | ¿Tasa vigente? |
| Seguro Educativo empleado | 1.25 % | Ver punto 6 |
| Recargo hora extra diurna | 25 % | Art. 33 CT — confirmar |
| Recargo hora extra nocturna | 50 % | Confirmar |
| Vacaciones | 30 días/año | Art. 54 CT — confirmar |
| Décimo tercer mes | sí (1/12) | Confirmar |

## 2. Horas extra
- Valor hora = (salario mensual ÷ divisor) ÷ jornada (8h).
- Pago = horas × valor hora × (1 + recargo%).
- **Validar:** el recargo correcto (25 % diurno / 50 % nocturno) y si para
  trabajo doméstico aplica una jornada o tope distinto.

## 3. Valor del día (`divisor`)
- La app permite dividir el salario mensual entre **26** (por defecto) o **30**.
- **Validar:** qué divisor corresponde legalmente para días trabajados,
  ausencias, días libres y liquidación en trabajo doméstico.

## 4. Décimo tercer mes
- Acumulación: salario ÷ 12 por mes.
- Se paga 3 veces al año: **15 de abril, 15 de agosto, 15 de diciembre**.
- Proporcional en liquidación: (salario ÷ 12) × meses desde el último pago (tope 4).
- **Validar:** fechas de pago y método proporcional.

## 5. Vacaciones
- Acumulación mensual = (salario ÷ 12) × (días de vacaciones ÷ 30).
- Proporcional en liquidación = (salario ÷ 12) × meses desde el último aniversario
  (se redondea +1 mes si hay ≥ 15 días extra).
- **Validar:** método de cálculo y redondeo.

## 6. ⚠️ Deducciones al trabajador (punto importante)
En `calcularPago`, el **neto de la empleada** = quincena + extras + bonos
− ausencias − otras deducciones − cuota de préstamo.
- **NO** se descuenta el CSS empleado (9.75 %) ni el Seguro Educativo empleado
  (1.25 %) del pago neto.
- **Validar:** ¿debe descontarse el aporte del trabajador (CSS/SegEdu) de su
  salario neto, o el régimen de trabajo doméstico lo maneja distinto? (La
  calculadora de la landing sí muestra el descuento de CSS; conviene unificar el
  criterio con lo que diga la ley.)

## 7. Liquidación (`calcularLiquidacion`)
Conceptos sumados: días trabajados del período + vacaciones proporcionales +
décimo proporcional + prima de antigüedad + indemnización + preaviso.

- **Salario semanal** = salario mensual ÷ 4.3333.
- **Indemnización (despido injustificado)** = años × salario mensual, con **tope
  de 3 meses** (se suma +1 año si los meses extra ≥ 6).
  - **Validar:** ¿1 mes por año y tope de 3 meses es correcto para este caso?
- **Prima de antigüedad** (si ≥ 12 meses) = salario semanal × **1.92** × años
  (con fracción por meses).
  - ⚠️ **Validar con prioridad:** la constante **1.92**. La ley panameña fija la
    prima de antigüedad en una proporción específica (aprox. una semana de
    salario por año). Hay que confirmar que 1.92 reproduce exactamente la fórmula
    legal y documentar su origen.
- **Preaviso** = 1 semana si antigüedad < 24 meses; 2 semanas si ≥ 24 meses.
  - **Validar:** plazos y montos del preaviso.

## 8. Feriados
- 12 feriados oficiales cargados (`FERIADOS_PANAMA`), con recargo **150 %**
  (Art. 49 CT).
- **Validar:** lista de feriados vigentes y el recargo aplicado.

---

## Recomendación
Pasar este documento a un abogado laboral panameño para que confirme cada
fórmula/constante y deje por escrito la **base legal** (artículo del Código de
Trabajo o norma) de cada una — en especial los puntos **6** (deducciones al
trabajador) y **7** (prima de antigüedad / constante 1.92).
