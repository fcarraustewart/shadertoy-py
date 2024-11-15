import pygame
from pygame.locals import *
import os
import time
import zmq

class PyOGLApp():
    def __init__(self, screen_posX, screen_posY, screen_width, screen_height):
        os.environ['SDL_VIDEO_WINDOW_POS'] = "%d,%d" % (screen_posX,screen_posY)
        self.screen_width=screen_width
        self.screen_height=screen_height
        pygame.init()
        pygame.display.gl_set_attribute(pygame.GL_MULTISAMPLEBUFFERS, 1)
        pygame.display.gl_set_attribute(pygame.GL_MULTISAMPLESAMPLES, 4)
        pygame.display.gl_set_attribute(pygame.GL_CONTEXT_PROFILE_MASK, pygame.GL_CONTEXT_PROFILE_CORE)
        pygame.display.gl_set_attribute(pygame.GL_DEPTH_SIZE, 32)

        self.screen = pygame.display.set_mode((screen_width,screen_height), DOUBLEBUF | OPENGL)
        pygame.display.set_caption('ShaderToy OpenGL port')
        self.program_id = None
        self.clock = pygame.time.Clock()

    def mainloop(self):
        done = False
        context = zmq.Context()
        socket = context.socket(zmq.REP)
        socket.bind("tcp://*:5555")
        self.initialise()

        while not done:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    done = True
            #  Wait for next request from client
            try:
                # check for a message, this will not block
                message = socket.recv(flags=zmq.NOBLOCK)
                # a message has been received
                print("Message received:", message)
            except zmq.Again as e:
                pass

            self.display()
            pygame.display.flip()
            #  Send reply back to client
            #socket.send(b"World")
            self.clock.tick(60)
        pygame.quit()



