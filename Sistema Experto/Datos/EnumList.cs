using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SistemaExperto.Datos
{
    public static class EnumList
    {
        #region ides
        private static List<EntornoDesarrolloIntegrado> ides;
        public static List<EntornoDesarrolloIntegrado> IDEs
        {
            get {
                if (ides == null)
                {
                    ides = new List<EntornoDesarrolloIntegrado>
                    {
                        EntornoDesarrolloIntegrado.AndroidStudio,
                        EntornoDesarrolloIntegrado.IntelliJ,
                        EntornoDesarrolloIntegrado.Netbeans,
                        EntornoDesarrolloIntegrado.VisualStudio,
                        EntornoDesarrolloIntegrado.VisualStudioCode,
                        EntornoDesarrolloIntegrado.XCode,
                    };
                }

                return ides;
            }
        }
        #endregion

        #region lados de desarrollo
        private static List<LadoDesarrollo> ladoDesarrollo;
        public static List<LadoDesarrollo> LadoDesarrollo
        {
            get {
                if (ladoDesarrollo == null)
                {
                    ladoDesarrollo = new List<LadoDesarrollo>
                    {
                        Datos.LadoDesarrollo.Backend,
                        Datos.LadoDesarrollo.Frontend,
                    };
                }

                return ladoDesarrollo;
            }
        }
        #endregion

        #region lenguajes de programacion
        private static List<NombreLenguajeProgramacion> lenguajeProgramacion;
        public static List<NombreLenguajeProgramacion> LenguajeProgramacion
        {
            get {
                if (lenguajeProgramacion == null)
                {
                    lenguajeProgramacion = new List<NombreLenguajeProgramacion>()
                    {
                        NombreLenguajeProgramacion.C,
                        NombreLenguajeProgramacion.Cpp,
                        NombreLenguajeProgramacion.Cs,
                        NombreLenguajeProgramacion.CSS,
                        NombreLenguajeProgramacion.Dart,
                        NombreLenguajeProgramacion.Go,
                        NombreLenguajeProgramacion.HTML,
                        NombreLenguajeProgramacion.Java,
                        NombreLenguajeProgramacion.JavaScript,
                        NombreLenguajeProgramacion.Kotlin,
                        NombreLenguajeProgramacion.PHP,
                        NombreLenguajeProgramacion.Python,
                        NombreLenguajeProgramacion.Ruby,
                        NombreLenguajeProgramacion.Swift,
                        NombreLenguajeProgramacion.VisualBasic,
                    };
                }

                return lenguajeProgramacion;
            }
        }
        #endregion

        #region paradigmas
        private static List<Paradigma> paradigmas;
        public static List<Paradigma> Paradigmas
        {
            get {
                if (paradigmas == null)
                {
                    paradigmas = new List<Paradigma>()
                    {
                        Paradigma.Declarativo,
                        Paradigma.Estructurado,
                        Paradigma.Funcional,
                        Paradigma.Imperativo,
                        Paradigma.Logico,
                        Paradigma.OrientadoObjetos,
                    };
                }

                return paradigmas;
            }
        }
        #endregion

        #region plataformas
        private static List<Plataforma> plataformas;
        public static List<Plataforma> Plataformas
        {
            get {
                if (plataformas == null)
                {
                    plataformas = new List<Plataforma>()
                    {
                        Plataforma.Escritorio,
                        Plataforma.Movil,
                        Plataforma.Web,
                    };
                }

                return plataformas;
            }
        }
        #endregion

        #region procesadores
        private static List<Procesador> procesadores;
        public static List<Procesador> Procesadores
        {
            get {
                if (procesadores == null)
                {
                    procesadores = new List<Procesador>()
                    {
                        Procesador.I3,
                        Procesador.I5,
                        Procesador.I7,
                        Procesador.I9,
                    };
                }

                return procesadores;
            }
        }
        #endregion

        #region sistemas operativos
        private static List<SistemaOperativo> sistemasOperativos;
        public static List<SistemaOperativo> SistemasOperativos
        {
            get {
                if (sistemasOperativos == null)
                {
                    sistemasOperativos = new List<SistemaOperativo>()
                    {
                        SistemaOperativo.Android,
                        SistemaOperativo.IOS,
                        SistemaOperativo.Linux,
                        SistemaOperativo.MacOS,
                        SistemaOperativo.Windows,
                    };
                }

                return sistemasOperativos;
            }
        }
        #endregion

        #region tipado 1
        private static List<Tipado1> tipados1;
        public static List<Tipado1> Tipados1
        {
            get {
                if (tipados1 == null)
                {
                    tipados1 = new List<Tipado1>()
                    {
                        Tipado1.Debil,
                        Tipado1.Fuerte,
                    };
                }

                return tipados1;
            }
        }
        #endregion

        #region tipados 2
        private static List<Tipado2> tipados2;
        public static List<Tipado2> Tipados2
        {
            get {
                if (tipados2 == null)
                {
                    tipados2 = new List<Tipado2>()
                    {
                        Tipado2.Dinamico,
                        Tipado2.Estatico,
                        Tipado2.Pato,
                    };
                }

                return tipados2;
            }
        }
        #endregion
    }
}
