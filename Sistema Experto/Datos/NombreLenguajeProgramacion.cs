using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SistemaExperto.Datos
{
    public sealed class NombreLenguajeProgramacion : StringEnum
    {
        public static readonly NombreLenguajeProgramacion C = new NombreLenguajeProgramacion("C");
        public static readonly NombreLenguajeProgramacion Cpp = new NombreLenguajeProgramacion("C++");
        public static readonly NombreLenguajeProgramacion Cs = new NombreLenguajeProgramacion("C#");
        public static readonly NombreLenguajeProgramacion CSS = new NombreLenguajeProgramacion("CSS");
        public static readonly NombreLenguajeProgramacion Dart = new NombreLenguajeProgramacion("Dart");
        public static readonly NombreLenguajeProgramacion Go = new NombreLenguajeProgramacion("Go (Golang)");
        public static readonly NombreLenguajeProgramacion HTML = new NombreLenguajeProgramacion("HTML");
        public static readonly NombreLenguajeProgramacion Java = new NombreLenguajeProgramacion("Java");
        public static readonly NombreLenguajeProgramacion JavaScript = new NombreLenguajeProgramacion("JavaScript");
        public static readonly NombreLenguajeProgramacion Kotlin = new NombreLenguajeProgramacion("Kotlin");
        public static readonly NombreLenguajeProgramacion PHP = new NombreLenguajeProgramacion("PHP");
        public static readonly NombreLenguajeProgramacion Python = new NombreLenguajeProgramacion("Python");
        public static readonly NombreLenguajeProgramacion Ruby = new NombreLenguajeProgramacion("Ruby");
        public static readonly NombreLenguajeProgramacion Swift = new NombreLenguajeProgramacion("Swift");
        public static readonly NombreLenguajeProgramacion VisualBasic = new NombreLenguajeProgramacion("Visual Basic");

        private NombreLenguajeProgramacion(string id) : base(id) { }
    }
}
