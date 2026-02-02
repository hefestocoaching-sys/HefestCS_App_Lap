# Motor V3 Documentation

**Complete documentation suite for Motor V3 - AI-Powered Training Program Generation**

Version: 3.0.0 | Last Updated: February 2026

---

## Quick Navigation

### For End Users (Coaches & Trainers)
📘 **[User Guide](user-guide.md)** - Complete manual for using Motor V3
- Getting started
- Creating client profiles
- Generating programs
- Processing workout logs
- Interpreting analytics
- Common workflows and FAQ

### For Developers
🔧 **[Developer Guide](developer-guide.md)** - Technical documentation
- Setup and installation
- Code structure overview
- How to add new engines
- How to extend validators
- Testing guidelines
- Best practices

📚 **[API Reference](api-reference.md)** - Complete API documentation
- All public classes and methods
- Parameter descriptions
- Return types
- Code examples
- Error handling

🏗️ **[Architecture](architecture.md)** - System design (if exists)
- 5-layer architecture
- Pipeline overview
- Component interactions

### For Educators & Students
🎓 **[Teaching Material](../educational/teaching-material.md)** - Educational resources
- 8-week course structure
- Learning objectives
- Exercises and assignments
- 5 detailed case studies
- Quizzes and assessments
- 6 hands-on labs

🎤 **[Presentation Slides](../educational/presentation-slides.md)** - Exposition material
- 10-part presentation
- Scientific foundations
- Demo scenarios
- Roadmap and Q&A

---

## Documentation Structure

```
docs/
├── motor-v3/
│   ├── README.md (this file)
│   ├── user-guide.md (24KB, for coaches)
│   ├── developer-guide.md (39KB, for engineers)
│   ├── api-reference.md (36KB, complete API)
│   └── architecture.md (if exists)
│
├── educational/
│   ├── presentation-slides.md (30KB, exposition)
│   └── teaching-material.md (42KB, course materials)
│
└── scientific-foundation/
    ├── 01-volume.md (Semana 1-2)
    ├── 02-intensity.md (Semana 3)
    ├── 03-effort-rir.md (Semana 4)
    ├── 04-exercise-selection.md (Semana 5)
    ├── 05-configuration-distribution.md (Semana 6)
    ├── 06-progression-variation.md (Semana 7)
    └── 07-intensification-techniques.md (Bonus)
```

---

## Quick Start Paths

### Path 1: "I'm a Coach - How Do I Use This?"
1. Read **[User Guide](user-guide.md)** → Getting Started (15 min)
2. Follow **Creating Client Profiles** section (10 min)
3. Try **Generating Your First Program** (5 min)
4. Refer to **FAQ** as needed

**Total Time**: ~30 minutes to first generated plan

---

### Path 2: "I'm a Developer - How Do I Integrate This?"
1. Read **[Developer Guide](developer-guide.md)** → Setup (15 min)
2. Review **Code Structure Overview** (20 min)
3. Explore **[API Reference](api-reference.md)** (30 min)
4. Run **Example 1: Basic Program Generation** (10 min)
5. Write your first unit test (20 min)

**Total Time**: ~90 minutes to working integration

---

### Path 3: "I'm a Student - How Do I Learn This?"
1. Read **[Teaching Material](../educational/teaching-material.md)** → Module 1 (Week 1-2)
2. Watch recommended videos (30 min)
3. Complete **Exercise 1: Calculate MEV/MAV/MRV** (30 min)
4. Continue through 8-week course structure

**Total Time**: 16 hours over 8 weeks

---

### Path 4: "I'm Presenting Motor V3 - What Do I Show?"
1. Review **[Presentation Slides](../educational/presentation-slides.md)** (30 min)
2. Practice **Demo Scenario 1** (normal client) (10 min)
3. Practice **Demo Scenario 2** (blocked client) (10 min)
4. Review **Q&A Talking Points** (15 min)
5. Prepare Firestore console for live ML data show (5 min)

**Total Time**: ~70 minutes preparation

---

## Key Concepts Reference

### Scientific Foundations (7 Semanas)

| Semana | Concept | Key Takeaway |
|--------|---------|--------------|
| **1-2** | Volume (MEV/MAV/MRV) | Chest MAV: 14 sets/week |
| **3** | Intensity Distribution | 35% Heavy, 45% Moderate, 20% Light |
| **4** | Effort (RIR/RPE) | RIR 2-3 optimal for compounds |
| **5** | Exercise Selection | 6 scoring criteria (ROM, angle, etc.) |
| **6** | Split Configuration | Full Body (3d), U/L (4d), PPL (5-6d) |
| **7** | Periodization | Wave loading: Accumulation → Deload |
| **Bonus** | Intensification | Drop sets, rest-pause, clusters |

**Full Details**: See [scientific-foundation/](../scientific-foundation/) folder

---

### Motor V3 Architecture

**5 Layers:**
1. **Knowledge Base** - Constants, scientific rules
2. **Intelligent Generation** - Volume, split, exercise selection
3. **Adaptive Personalization** - Exercise swaps, preferences
4. **Reactive Motors** - Load progression, deload triggers
5. **AI/ML** - Predictions, pattern detection

**7-Phase Pipeline:**
```
Context Building → Feature Engineering → Decision Making → 
ML Logging → Readiness Gate → Plan Generation → Result Assembly
```

---

### 38 Features in FeatureVector

**Categories:**
- **Demographics** (5): age, gender, BMI
- **Experience** (3): years training, level
- **Volume** (4): weekly sets, tolerance
- **Recovery** (6): sleep, stress, soreness
- **Intensity** (3): RIR, RPE, optimality
- **Optimization** (2): deload frequency
- **Longitudinal** (3): adherence, performance trend
- **Objectives** (8): goal + focus (one-hot encoded)
- **Derived** (6): fatigue index, readiness score, overreaching risk, etc.

**Full Formulas**: See [API Reference → FeatureVector](api-reference.md#feature-engineering)

---

## Common Questions

### Q: Where do I start?
**A:** Depends on your role:
- **Coach**: [User Guide](user-guide.md)
- **Developer**: [Developer Guide](developer-guide.md)
- **Student**: [Teaching Material](../educational/teaching-material.md)
- **Presenter**: [Presentation Slides](../educational/presentation-slides.md)

### Q: How do I generate my first training plan?
**A:** See [User Guide → Generating Your First Program](user-guide.md#generating-your-first-program)

### Q: What if a plan gets blocked?
**A:** See [User Guide → Understanding Blocked Plans](user-guide.md#understanding-blocked-plans)

### Q: How do I add a new decision strategy?
**A:** See [Developer Guide → How to Add New Engines](developer-guide.md#how-to-add-new-engines)

### Q: What are the 38 features?
**A:** See [API Reference → FeatureVector](api-reference.md#featurevector)

### Q: How does ML learning work?
**A:** See [Developer Guide → ML Pipeline](developer-guide.md#integration-patterns) or [Presentation Slides → ML Pipeline](../educational/presentation-slides.md)

---

## Documentation Quality Standards

All Motor V3 documentation follows these standards:

✅ **Comprehensive**: Covers all features and use cases  
✅ **Professional**: Clear, concise, well-structured  
✅ **Aligned**: Reflects actual Motor V3 implementation  
✅ **Scientific**: Backed by Israetel/Schoenfeld/Helms research  
✅ **Practical**: Includes real examples and code  
✅ **Accessible**: Multiple entry points for different audiences  

---

## Contributing to Documentation

Found an error or want to improve docs?

1. **Small fixes**: Edit directly via GitHub PR
2. **New sections**: Discuss in Issues first
3. **Code examples**: Ensure they compile and run
4. **Scientific claims**: Cite sources (papers, books)

**Contact**: docs@hefestcs.com

---

## Version History

- **v3.0.0** (Feb 2026): Initial Motor V3 documentation suite
  - User Guide (24KB)
  - Developer Guide (39KB)
  - API Reference (36KB)
  - Presentation Slides (30KB)
  - Teaching Material (42KB)
  - Total: 171KB, 5 comprehensive guides

---

## Support & Community

- **Email**: support@hefestcs.com
- **Documentation**: https://docs.hefestcs.com/motor-v3
- **GitHub**: https://github.com/hefestocoaching-sys/HefestCS_App_Lap
- **Discord**: #motor-v3-docs

---

**Motor V3 Documentation Team**  
February 2026
