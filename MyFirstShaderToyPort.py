from glapp.PyOGLApp import *
from glapp.Utils import *
from glapp.Mesh import *

UART_SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
UART_RX_CHAR_UUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
UART_TX_CHAR_UUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"


class MyFirstShaderToyPort(PyOGLApp):
    def __init__(self):
        super().__init__(850,100,1024,768)
        self.screen_plane = None

    def initialise(self):
        self.program_id = create_program(open("shaders/vert.vs").read(), open("shaders/frag.vs").read())
        self.screen_plane = Mesh(self.program_id)
        print("Init")

    def display(self):
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        glUseProgram(self.program_id)
        res_id = glGetUniformLocation(self.program_id, "iResolution")
        glUniform2f(res_id, self.screen_width, self.screen_height)
        self.screen_plane.draw()

InstanceShader = MyFirstShaderToyPort()
InstanceShader.mainloop()