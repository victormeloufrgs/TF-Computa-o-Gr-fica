#version 330 core

// Atributos de fragmentos recebidos como entrada ("in") pelo Fragment Shader.
// Neste exemplo, este atributo foi gerado pelo rasterizador como a
// interpolação da posição global e a normal de cada vértice, definidas em
// "shader_vertex.glsl" e "main.cpp".

in vec4 position_world;
in vec4 normal;
in vec4 color_v;

// Posição do vértice atual no sistema de coordenadas local do modelo.
in vec4 position_model;

// Coordenadas de textura obtidas do arquivo OBJ (se existirem!)
in vec2 texcoords;

// Matrizes computadas no código C++ e enviadas para a GPU
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

// Identificador que define qual objeto está sendo desenhado no momento
#define HORIZON 0
#define BUNNY  1
#define PLANE  2
#define WEAPON 3
#define BALA 4
uniform int object_id;

// Parâmetros da axis-aligned bounding box (AABB) do modelo
uniform vec4 bbox_min;
uniform vec4 bbox_max;

// Variáveis para acesso das imagens de textura
uniform sampler2D TextureImage0;
uniform sampler2D TextureImage1;
uniform sampler2D TextureImage2;

// O valor de saída ("out") de um Fragment Shader é a cor final do fragmento.
out vec3 color;
out vec3 color_blinn;
out vec3 color_gouraud;

// Constantes
#define M_PI   3.14159265358979323846
#define M_PI_2 1.57079632679489661923

void main()
{
    // Obtemos a posição da câmera utilizando a inversa da matriz que define o
    // sistema de coordenadas da câmera.

    vec4 origin = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 camera_position = inverse(view) * origin;

    // O fragmento atual é coberto por um ponto que percente à superfície de um
    // dos objetos virtuais da cena. Este ponto, p, possui uma posição no
    // sistema de coordenadas global (World coordinates). Esta posição é obtida
    // através da interpolação, feita pelo rasterizador, da posição de cada
    // vértice.

    vec4 p = position_world;

    // Normal do fragmento atual, interpolada pelo rasterizador a partir das
    // normais de cada vértice.
    vec4 n = normalize(normal);

    // Vetor que define o sentido da fonte de luz em relação ao ponto atual.
    vec4 l = normalize(vec4(1.0,1.0,0.0,0.0));

    // Vetor que define o sentido da câmera em relação ao ponto atual.
    vec4 v = normalize(camera_position - p);


    // Vetor que define o sentido da reflex�o especular ideal.
    vec4 r = -l+2*n*dot(n,l);

    //vetor h //  blinn_phong Termo Especualar

    vec4 h = (v + l) / (abs(v+l));

    // Par�metros que definem as propriedades espectrais da superf�cie
    vec3 Kd; // Reflet�ncia difusa
    vec3 Ks; // Reflet�ncia especular
    vec3 Ka; // Reflet�ncia ambiente
    float q; // Expoente especular para o modelo de ilumina��o de Phong

    // Coordenadas de textura U e V
    float U = 0.0;
    float V = 0.0;

    if ( object_id == HORIZON )
    {
        // PREENCHA AQUI as coordenadas de textura da esfera, computadas com
        // projeção esférica EM COORDENADAS DO MODELO. Utilize como referência
        // o slide 144 do documento "Aula_20_e_21_Mapeamento_de_Texturas.pdf".
        // A esfera que define a projeção deve estar centrada na posição
        // "bbox_center" definida abaixo.

        // Você deve utilizar:
        //   função 'length( )' : comprimento Euclidiano de um vetor
        //   função 'atan( , )' : arcotangente. Veja https://en.wikipedia.org/wiki/Atan2.
        //   função 'asin( )'   : seno inverso.
        //   constante M_PI
        //   variável position_model

        vec4 bbox_center = (bbox_min + bbox_max) / 2.0;

        float ro = 1;

        vec4 p_linha = bbox_center + ro * ((position_model - bbox_center)/(length(position_model-bbox_center)));

        vec4 p_vet = p_linha - bbox_center;

        float tetha = atan(p_vet.x, p_vet.z);
        float phi = asin(p_vet.y/ro);

        U = ((tetha + M_PI)/(2*M_PI));
        V = ((phi + (M_PI/2))/M_PI);
    }
    else if ( object_id == BUNNY )
    {
        // PREENCHA AQUI as coordenadas de textura do coelho, computadas com
        // projeção planar XY em COORDENADAS DO MODELO. Utilize como referência
        // o slide 111 do documento "Aula_20_e_21_Mapeamento_de_Texturas.pdf",
        // e também use as variáveis min*/max* definidas abaixo para normalizar
        // as coordenadas de textura U e V dentro do intervalo [0,1]. Para
        // tanto, veja por exemplo o mapeamento da variável 'p_v' utilizando
        // 'h' no slide 154 do documento "Aula_20_e_21_Mapeamento_de_Texturas.pdf".
        // Veja também a Questão 4 do Questionário 4 no Moodle.

//        float minx = bbox_min.x;
//        float maxx = bbox_max.x;

//        float miny = bbox_min.y;
//        float maxy = bbox_max.y;

//        float minz = bbox_min.z;
//        float maxz = bbox_max.z;

//        U = (position_model.x - bbox_min.x)/(bbox_max.x - bbox_min.x);
//        V = (position_model.y - bbox_min.y)/(bbox_max.y - bbox_min.y);

        Kd = vec3(0.08, 0.4, 0.8);
        Ks = vec3(0.8, 0.8, 0.8);
        Ka = vec3(0.04, 0.2, 0.4);
        q = 32.0;
    }
    else if ( object_id == PLANE )
    {
        // Coordenadas de textura do plano, obtidas do arquivo OBJ.

        U = fract(texcoords.x*800);
        V = fract(texcoords.y*800);
    }
    else if (object_id == WEAPON) {
        Kd = vec3(0.2,0.2,0.2);
        Ks = vec3(0.3,0.3,0.3);
        Ka = vec3(0.0,0.0,0.0);
        q = 20.0;

//        vec4 bbox_center = (bbox_min + bbox_max) / 2.0;

//       U = 0.0;
//       V = 0.0;
    } else if (object_id == BALA) {
        Kd = vec3(0.2,0.2,0.2);
        Ks = vec3(0.3,0.3,0.3);
        Ka = vec3(0.0,0.0,0.0);
        q = 20.0;

//        vec4 bbox_center = (bbox_min + bbox_max) / 2.0;

//       U = 0.0;
//       V = 0.0;
    }

    if (object_id == PLANE || object_id == HORIZON) {

        // Obtemos a refletância difusa a partir da leitura da imagem TextureImage0
        vec3 Kd0 = texture(TextureImage0, vec2(U,V)).rgb;
        vec3 Kd1 = texture(TextureImage1, vec2(U,V)).rgb;

        // Equação de Iluminação
        float lambert = max(0,dot(n,l));

        if (object_id == PLANE) {
            color = Kd0 * (lambert + 0.01);
        } else {
            color = Kd1;
        }

    } else {

    // Espectro da fonte de ilumina��o
        vec3 I = vec3(1.0,1.0,1.0); // PREENCH AQUI o espectro da fonte de luz

        // Espectro da luz ambiente
        vec3 Ia = vec3(0.2,0.2,0.2); // PREENCHA AQUI o espectro da luz ambiente

        // Termo difuso utilizando a lei dos cossenos de Lambert
        vec3 lambert_diffuse_term = Kd*I*max(0,dot(n,l))+Ka*Ia;


//vec3(0.0,0.0,0.0); // PREENCHA AQUI o termo difuso de Lambert

        // Termo ambiente
        vec3 ambient_term = Ka*Ia;//vec3(0.0,0.0,0.0); // PREENCHA AQUI o termo ambiente

        // Termo especular utilizando o modelo de ilumina��o de Phong
        vec3 phong_specular_term  = Ks*I*max(0,pow(dot(r,v),q));

        // Termo especular utilizando o modelo de ilumina��o de Blinn Phong
        vec3 blinn_phong_specular_term  = Ks*I*(pow(dot(n,h),q));

        // Cor final do fragmento calculada com uma combina��o dos termos difuso,
        // especular, e ambiente. Veja slide 133 do documento "Aula_17_e_18_Modelos_de_Iluminacao.pdf".

        color = lambert_diffuse_term + ambient_term + phong_specular_term;

        color_blinn = lambert_diffuse_term + ambient_term + blinn_phong_specular_term;
    }

    // Cor final com correção gamma, considerando monitor sRGB.
    // Veja https://en.wikipedia.org/w/index.php?title=Gamma_correction&oldid=751281772#Windows.2C_Mac.2C_sRGB_and_TV.2Fvideo_standard_gammas

    color = pow(color, vec3(1.0,1.0,1.0)/2.2);

    color_blinn = pow(color_blinn, vec3(1.0,1.0,1.0)/2.2);

    //color_gouraud = color_v;



}
