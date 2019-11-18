using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SistemaExperto.Datos
{
    public class LenguajeProgramacion
    {
        public NombreLenguajeProgramacion Nombre { get; set; }
        public Tipado1 Tipado1 { get; set; }
        public Tipado2 Tipado2 { get; set; }
        public Paradigma Paradigma { get; set; }
    }
}
